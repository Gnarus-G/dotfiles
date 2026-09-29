/**
 * Commit Subagent Extension
 *
 * Registers the `commit` tool: delegates the commit workflow to a `pi`
 * subprocess running DeepSeek (bash tool only, isolated context) that runs
 * `git-ac` on the exact paths provided and reports the commit hash and
 * subject. Keeps git operations out of the primary agent's context.
 */

import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";
import { Type } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SUBAGENT_MODEL = "ollama-cloud/deepseek-v4.1-flash";

const SYSTEM_PROMPT = [
	"Run exactly one command: `git-ac -y -- <paths>`, replacing `<paths>` with only",
	"the paths named in the task (quote paths as the shell requires), then report",
	"its commit hash and subject; do not inspect the repository or run any other",
	"command.",
].join(" ");

interface SubagentResult {
	model: string;
	exitCode: number;
	stopReason?: string;
	text: string;
	commands: string[];
	stderr: string;
	errorMessage?: string;
}

function getPiInvocation(args: string[]): { command: string; args: string[] } {
	const currentScript = process.argv[1];
	const isBunVirtualScript = currentScript?.startsWith("/$bunfs/root/");
	if (currentScript && !isBunVirtualScript && fs.existsSync(currentScript)) {
		return { command: process.execPath, args: [currentScript, ...args] };
	}

	const execName = path.basename(process.execPath).toLowerCase();
	const isGenericRuntime = /^(node|bun)(\.exe)?$/.test(execName);
	if (!isGenericRuntime) {
		return { command: process.execPath, args };
	}

	return { command: "pi", args };
}

function runCommitSubagent(cwd: string, paths: string[], signal?: AbortSignal): Promise<SubagentResult> {
	const args = [
		"--mode",
		"json",
		"-p",
		"--no-session",
		"--model",
		SUBAGENT_MODEL,
		"--thinking",
		"off",
		"--tools",
		"bash",
		"--append-system-prompt",
		SYSTEM_PROMPT,
		`Task: Run git-ac on exactly these paths, one per line:\n${paths.join("\n")}`,
	];

	const result: SubagentResult = {
		model: SUBAGENT_MODEL,
		exitCode: 0,
		text: "",
		commands: [],
		stderr: "",
	};

	return new Promise((resolve, reject) => {
		const invocation = getPiInvocation(args);
		const proc = spawn(invocation.command, invocation.args, {
			cwd,
			shell: false,
			stdio: ["ignore", "pipe", "pipe"],
		});

		let buffer = "";
		const processLine = (line: string) => {
			if (!line.trim()) return;
			let event: any;
			try {
				event = JSON.parse(line);
			} catch {
				return;
			}
			if (event.type !== "message_end" || event.message?.role !== "assistant") return;
			const message = event.message;
			result.stopReason = message.stopReason ?? result.stopReason;
			result.errorMessage = message.errorMessage ?? result.errorMessage;
			for (const part of message.content) {
				if (part.type === "text") result.text = part.text;
				else if (part.type === "toolCall" && part.name === "bash") {
					result.commands.push(String(part.arguments?.command ?? "").slice(0, 200));
				}
			}
		};

		proc.stdout.on("data", (data) => {
			buffer += data.toString();
			const lines = buffer.split("\n");
			buffer = lines.pop() || "";
			for (const line of lines) processLine(line);
		});
		proc.stderr.on("data", (data) => {
			result.stderr += data.toString();
		});

		let killed = false;
		const killProc = () => {
			killed = true;
			proc.kill("SIGTERM");
			setTimeout(() => {
				if (!proc.killed) proc.kill("SIGKILL");
			}, 5000);
		};
		if (signal) {
			if (signal.aborted) killProc();
			else signal.addEventListener("abort", killProc, { once: true });
		}

		proc.on("error", (error) => reject(error));
		proc.on("close", (code) => {
			if (buffer.trim()) processLine(buffer);
			result.exitCode = code ?? 0;
			if (killed) reject(new Error("Commit subagent was aborted"));
			else resolve(result);
		});
	});
}

export default function commitSubagentExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "commit",
		label: "Commit",
		description: [
			"Delegate the commit workflow to the commit subagent (DeepSeek, isolated context).",
			"It stages exactly the given paths, commits them with git-ac, and reports the commit hash and subject.",
			"Use when asked to commit or create a commit.",
		].join(" "),
		promptSnippet: "Delegate commits to the commit subagent with the exact session paths",
		promptGuidelines: [
			"When the user asks to commit, call the commit tool with the exact session paths instead of running git commands yourself.",
		],
		parameters: Type.Object({
			paths: Type.Array(Type.String(), {
				minItems: 1,
				description: "Exact paths changed in this session; nothing else is staged or committed",
			}),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const result = await runCommitSubagent(ctx.cwd, params.paths, signal);
			const failed =
				result.exitCode !== 0 || result.stopReason === "error" || result.stopReason === "aborted";
			let text = failed
				? `Commit subagent failed (${result.stopReason ?? `exit ${result.exitCode}`}): ${result.errorMessage || result.stderr || result.text || "(no output)"}`
				: result.text || "(no output)";
			if (result.commands.length > 0) {
				text += `\n\nCommands:\n${result.commands.map((command) => `- ${command}`).join("\n")}`;
			}
			return {
				content: [{ type: "text", text }],
				details: result,
				...(failed ? { isError: true } : {}),
			};
		},
	});
}