/**
 * Tmux Panes Extension
 *
 * Adds /tmux for selecting a tmux pane, then hands the selected pane id to
 * the model so it can decide how much scrollback to capture with tmux_panes.
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

function requestPaneCapture(pi: ExtensionAPI, ctx: ExtensionCommandContext, pane: PaneInfo): void {
	const prompt = [
		`Inspect tmux pane ${pane.id} (${pane.label}).`,
		"Use the tmux_panes tool with action=\"capture\" and this target.",
		"Choose the line count yourself based on the current request/context.",
	].join("\n");

	if (ctx.isIdle()) {
		pi.sendUserMessage(prompt);
	} else {
		pi.sendUserMessage(prompt, { deliverAs: "followUp" });
		ctx.ui.notify("Queued tmux pane capture request", "info");
	}
}

async function selectAndRequestCapture(pi: ExtensionAPI, ctx: ExtensionCommandContext, visibleOnly = true): Promise<void> {
	const panes = (await listPanes(pi)).filter((pane) => !visibleOnly || pane.visible);
	if (panes.length === 0) {
		ctx.ui.notify(visibleOnly ? "No visible tmux panes found. Try /tmux all" : "No tmux panes found", "warning");
		return;
	}

	const pane = await choosePane(ctx, panes);
	if (pane) requestPaneCapture(pi, ctx, pane);
}

export default function tmuxPanesExtension(pi: ExtensionAPI) {
	pi.registerCommand("tmux", {
		description: "Select a tmux pane for the model to capture",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) return;
			try {
				await selectAndRequestCapture(pi, ctx, !(args ?? "").includes("all"));
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
			}
		},
	});

	pi.registerShortcut(Key.ctrlShift("t"), {
		description: "Select tmux pane for capture",
		handler: async (ctx) => {
			try {
				await selectAndRequestCapture(pi, ctx, true);
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
			}
		},
	});

	pi.registerTool({
		name: "tmux_panes",
		label: "Tmux Panes",
		description: "List tmux panes with visibility or capture scrollback from a selected pane. Output is capped to 10,000 lines.",
		promptSnippet: "List visible/all tmux panes or capture scrollback from a selected pane",
		promptGuidelines: [
			"Use tmux_panes when the user asks to inspect text from another tmux pane instead of using bash tmux commands directly.",
		],
		parameters: Type.Object({
			action: StringEnum(["list", "capture"] as const),
			target: Type.Optional(Type.String({ description: "tmux pane id such as %4; required for capture" })),
			visibleOnly: Type.Optional(Type.Boolean({ description: "Only include visible panes when listing; default true" })),
			lines: Type.Optional(Type.Number({ description: "Scrollback lines to capture, max 10000; default 1000" })),
		}),
		async execute(_toolCallId, params) {
			if (params.action === "list") {
				const visibleOnly = params.visibleOnly ?? true;
				const panes = (await listPanes(pi)).filter((pane) => !visibleOnly || pane.visible);
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
