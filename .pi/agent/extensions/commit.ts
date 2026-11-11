/** Commit exact session paths through git-ac's Codex → Ollama fallback. */
import { Type } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function commitExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "commit",
		label: "Commit",
		description:
			"Commit exactly the given session paths using git-ac (Codex subscription first, Ollama fallback).",
		promptSnippet: "Commit exact session paths through git-ac",
		promptGuidelines: [
			"When the user asks to commit, call the commit tool with the exact session paths.",
		],
		parameters: Type.Object({
			paths: Type.Array(Type.String(), {
				minItems: 1,
				description: "Exact paths changed in this session; nothing else is staged or committed",
			}),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const result = await pi.exec("git-ac", ["-y", "--", ...params.paths], {
				cwd: ctx.cwd,
				signal,
			});
			return {
				content: [{
					type: "text",
					text: [result.stdout, result.stderr].filter(Boolean).join("\n") || "(no output)",
				}],
				details: result,
				...(result.code !== 0 ? { isError: true } : {}),
			};
		},
	});
}
