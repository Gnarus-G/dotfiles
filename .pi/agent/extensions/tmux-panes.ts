/**
 * Tmux Panes Extension
 *
 * Adds /tmux-panes for selecting visible/all tmux panes, viewing scrollback,
 * selecting line ranges, and yanking text to clipboard or the Pi editor.
 */

import { spawn } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { DynamicBorder } from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Container, Key, type SelectItem, SelectList, Text, matchesKey, truncateToWidth } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { parsePaneRows, selectedText } from "./tmux-panes-lib.mjs";

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

async function writeClipboard(text: string): Promise<string> {
	const candidates = [
		["clip"],
		["wl-copy"],
		["xclip", "-selection", "clipboard"],
		["xsel", "--clipboard", "--input"],
	];

	for (const command of candidates) {
		try {
			await new Promise<void>((resolve, reject) => {
				const child = spawn(command[0]!, command.slice(1), { stdio: ["pipe", "ignore", "ignore"] });
				child.on("error", reject);
				child.on("close", (code) => (code === 0 ? resolve() : reject(new Error(`${command[0]} exited ${code}`))));
				child.stdin.end(text);
			});
			return command[0]!;
		} catch {
			// Try the next clipboard provider.
		}
	}

	throw new Error("No clipboard command found: tried clip, wl-copy, xclip, xsel");
}

async function choosePane(ctx: ExtensionContext, panes: PaneInfo[]): Promise<PaneInfo | null> {
	const items: SelectItem[] = panes.map((pane) => ({
		value: pane.id,
		label: pane.label,
		description: pane.description,
	}));

	const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
		const container = new Container();
		container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));
		container.addChild(new Text(theme.fg("accent", theme.bold("Select tmux pane")), 1, 0));
		const selectList = new SelectList(items, Math.min(items.length, 12), {
			selectedPrefix: (s) => theme.fg("accent", s),
			selectedText: (s) => theme.fg("accent", s),
			description: (s) => theme.fg("muted", s),
			scrollInfo: (s) => theme.fg("dim", s),
			noMatch: (s) => theme.fg("warning", s),
		});
		selectList.onSelect = (item) => done(item.value);
		selectList.onCancel = () => done(null);
		container.addChild(selectList);
		container.addChild(new Text(theme.fg("dim", "● visible • ○ hidden • ↑↓ navigate • enter view • esc cancel"), 1, 0));
		container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));

		return {
			render: (width: number) => container.render(width),
			invalidate: () => container.invalidate(),
			handleInput: (data: string) => {
				selectList.handleInput(data);
				tui.requestRender();
			},
		};
	});

	return panes.find((pane) => pane.id === result) ?? null;
}

async function viewPane(ctx: ExtensionContext, pi: ExtensionAPI, pane: PaneInfo): Promise<void> {
	let lines = await capturePane(pi, pane.id);
	const action = await ctx.ui.custom<{ kind: "yank" | "insert"; text: string } | null>((tui, theme, _kb, done) => {
		let top = Math.max(0, lines.length - 30);
		let cursor = Math.max(0, lines.length - 1);
		let anchor: number | undefined;

		function clamp() {
			cursor = Math.max(0, Math.min(cursor, lines.length - 1));
			top = Math.max(0, Math.min(top, Math.max(0, lines.length - 1)));
		}

		function selection() {
			return selectedText(lines, anchor ?? cursor, cursor);
		}

		function move(delta: number, height = 20) {
			cursor += delta;
			clamp();
			if (cursor < top) top = cursor;
			if (cursor >= top + height) top = cursor - height + 1;
		}

		return {
			render(width: number) {
				const height = 20;
				clamp();
				const selectedStart = anchor === undefined ? cursor : Math.min(anchor, cursor);
				const selectedEnd = anchor === undefined ? cursor : Math.max(anchor, cursor);
				const bodyWidth = Math.max(10, width - 7);
				const rendered = [
					theme.fg("accent", theme.bold(`tmux ${pane.sessionName}:${pane.windowIndex}.${pane.paneIndex} ${pane.command} ${pane.size}`)),
					theme.fg("dim", `${pane.path} — lines ${top + 1}-${Math.min(lines.length, top + height)} of ${lines.length}`),
					"",
				];

				for (let i = top; i < Math.min(lines.length, top + height); i++) {
					const number = String(i + 1).padStart(4, " ");
					const prefix = i === cursor ? theme.fg("accent", ">") : " ";
					let text = `${prefix}${theme.fg("dim", number)} ${truncateToWidth(lines[i] ?? "", bodyWidth)}`;
					if (i >= selectedStart && i <= selectedEnd) text = theme.bg("selectedBg", text);
					rendered.push(truncateToWidth(text, width, ""));
				}

				rendered.push("");
				rendered.push(theme.fg("dim", "↑↓ scroll • PgUp/PgDn page • space mark range • y/enter yank • i insert • r refresh • esc close"));
				return rendered.map((line) => truncateToWidth(line, width, ""));
			},
			invalidate() {},
			handleInput(data: string) {
				if (matchesKey(data, Key.escape)) return done(null);
				if (matchesKey(data, Key.up)) move(-1);
				else if (matchesKey(data, Key.down)) move(1);
				else if (matchesKey(data, "pageup") || matchesKey(data, Key.ctrl("u"))) move(-10);
				else if (matchesKey(data, "pagedown") || matchesKey(data, Key.ctrl("d"))) move(10);
				else if (matchesKey(data, Key.home)) {
					cursor = 0;
					top = 0;
				} else if (matchesKey(data, Key.end)) {
					cursor = Math.max(0, lines.length - 1);
					top = Math.max(0, lines.length - 20);
				} else if (matchesKey(data, Key.space)) {
					anchor = anchor === undefined ? cursor : undefined;
				} else if (matchesKey(data, Key.enter) || data === "y") {
					done({ kind: "yank", text: selection() });
				} else if (data === "i") {
					done({ kind: "insert", text: selection() });
				} else if (data === "r") {
					capturePane(pi, pane.id).then((next) => {
						lines = next;
						cursor = Math.max(0, lines.length - 1);
						top = Math.max(0, lines.length - 20);
						tui.requestRender();
					}).catch((error) => ctx.ui.notify(String(error), "error"));
				}
				tui.requestRender();
			},
		};
	});

	if (!action) return;
	if (action.kind === "insert") {
		ctx.ui.pasteToEditor(action.text);
		ctx.ui.notify(`Inserted ${action.text.split("\n").length} line(s) into editor`, "info");
		return;
	}
	const provider = await writeClipboard(action.text);
	ctx.ui.notify(`Yanked ${action.text.split("\n").length} line(s) via ${provider}`, "info");
}

export default function tmuxPanesExtension(pi: ExtensionAPI) {
	pi.registerCommand("tmux", {
		description: "Select tmux panes, view scrollback, and yank text",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) return;
			const visibleOnly = !(args ?? "").includes("all");
			try {
				const panes = (await listPanes(pi)).filter((pane) => !visibleOnly || pane.visible);
				if (panes.length === 0) {
					ctx.ui.notify(visibleOnly ? "No visible tmux panes found. Try /tmux all" : "No tmux panes found", "warning");
					return;
				}
				const pane = await choosePane(ctx, panes);
				if (pane) await viewPane(ctx, pi, pane);
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
			}
		},
	});

	pi.registerShortcut(Key.ctrlShift("t"), {
		description: "Open tmux pane viewer",
		handler: async (ctx) => {
			try {
				const panes = (await listPanes(pi)).filter((pane) => pane.visible);
				if (panes.length === 0) {
					ctx.ui.notify("No visible tmux panes found", "warning");
					return;
				}
				const pane = await choosePane(ctx, panes);
				if (pane) await viewPane(ctx, pi, pane);
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
