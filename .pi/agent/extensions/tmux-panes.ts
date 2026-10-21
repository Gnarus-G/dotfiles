/**
 * Tmux Panes Extension
 *
 * Adds /tmux for selecting and inspecting a tmux pane.
 */

import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Key } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { parsePaneRows } from "./tmux-panes-lib.mjs";

type PaneInfo = ReturnType<typeof parsePaneRows>[number];

const PANE_FORMAT = [
	"#{session_name}",
	"#{window_index}",
	"#{window_name}",
	"#{pane_index}",
	"#{pane_id}",
	"#{pane_active}",
	"#{window_active}",
	"#{window_zoomed_flag}",
	"#{session_attached}",
	"#{pane_visible}",
	"#{pane_current_command}",
	"#{pane_current_path}",
	"#{pane_width}x#{pane_height}",
	"#{pane_title}",
].join("\t");

async function listPanes(pi: ExtensionAPI): Promise<PaneInfo[]> {
	const result = await pi.exec("tmux", ["list-panes", "-a", "-F", PANE_FORMAT], { timeout: 3000 });
	if (result.code !== 0) throw new Error(result.stderr || "tmux list-panes failed");
	return parsePaneRows(result.stdout);
}

async function capturePane(pi: ExtensionAPI, target: string, lines = 1000): Promise<string[]> {
	const start = `-${Math.max(1, Math.min(lines, 10000))}`;
	const result = await pi.exec("tmux", ["capture-pane", "-pJ", "-S", start, "-t", target], { timeout: 3000 });
	if (result.code !== 0) throw new Error(result.stderr || `tmux capture-pane failed for ${target}`);
	return result.stdout.replace(/\s+$/u, "").split("\n");
}

async function choosePane(ctx: ExtensionCommandContext, panes: PaneInfo[]): Promise<PaneInfo | null> {
	const choices = new Map(panes.map((pane) => [`${pane.label}  [${pane.id}]`, pane]));
	const choice = await ctx.ui.select("Select tmux pane", [...choices.keys()]);
	return choice ? choices.get(choice) ?? null : null;
}

async function inspectPane(pi: ExtensionAPI, ctx: ExtensionCommandContext, pane: PaneInfo): Promise<void> {
	const lines = await capturePane(pi, pane.id, 200);
	const prompt = [
		`Selected tmux pane ${pane.id} (${pane.label}):`,
		"<tmux-pane>",
		...lines,
		"</tmux-pane>",
		"Proceed if the next step is clear from context; otherwise ask what to do. Capture more with tmux_panes if needed.",
	].join("\n");

	if (ctx.isIdle()) {
		pi.sendUserMessage(prompt);
	} else {
		pi.sendUserMessage(prompt, { deliverAs: "followUp" });
		ctx.ui.notify("Queued tmux pane inspection", "info");
	}
}

async function selectAndRequestCapture(pi: ExtensionAPI, ctx: ExtensionCommandContext): Promise<void> {
	const panes = await listPanes(pi);
	if (panes.length === 0) {
		ctx.ui.notify("No tmux panes found", "warning");
		return;
	}

	const pane = await choosePane(ctx, panes);
	if (pane) await inspectPane(pi, ctx, pane);
}

export default function tmuxPanesExtension(pi: ExtensionAPI) {
	pi.registerCommand("tmux", {
		description: "Select and inspect a tmux pane",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) return;
			try {
				await selectAndRequestCapture(pi, ctx);
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
			}
		},
	});

	pi.registerShortcut(Key.ctrlShift("t"), {
		description: "Select and inspect a tmux pane",
		handler: async (ctx) => {
			try {
				await selectAndRequestCapture(pi, ctx);
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
			}
		},
	});

	pi.registerTool({
		name: "tmux_panes",
		label: "Tmux Panes",
		description: "List all tmux panes, including hidden panes, or capture scrollback from a selected pane. Output is capped to 10,000 lines.",
		promptSnippet: "List all tmux panes, including hidden panes, or capture scrollback from a selected pane",
		promptGuidelines: [
			"Use tmux_panes when the user asks to inspect text from another tmux pane instead of using bash tmux commands directly.",
		],
		parameters: Type.Object({
			action: StringEnum(["list", "capture"] as const),
			target: Type.Optional(Type.String({ description: "tmux pane id such as %4; required for capture" })),
			visibleOnly: Type.Optional(Type.Boolean({ description: "Deprecated; hidden panes are always included" })),
			lines: Type.Optional(Type.Number({ description: "Scrollback lines to capture, max 10000; default 1000" })),
		}),
		async execute(_toolCallId, params) {
			if (params.action === "list") {
				const panes = await listPanes(pi);
				return {
					content: [{ type: "text", text: panes.map((pane) => `${pane.id}\t${pane.label}\t${pane.description}`).join("\n") || "No panes found" }],
					details: { panes },
				};
			}

			if (!params.target) throw new Error("target is required for capture");
			const lines = await capturePane(pi, params.target, params.lines ?? 1000);
			return {
				content: [{ type: "text", text: lines.join("\n") }],
				details: { target: params.target, lines: lines.length },
			};
		},
	});
}
