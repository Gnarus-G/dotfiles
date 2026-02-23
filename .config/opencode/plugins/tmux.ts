import type { Plugin } from "@opencode-ai/plugin"

const COMMAND_LIST_PANES = "tmux-panes"
const COMMAND_SELECT_PANE = "tmux-pane"
const COMMAND_HELP = "tmux-help"
const DEFAULT_CAPTURE_LINES = 120

const selectedPaneBySession = new Map<string, string>()

type PaneInfo = {
  session: string
  windowIndex: string
  windowName: string
  paneIndex: string
  paneID: string
  command: string
  cwd: string
  title: string
  target: string
  namedTarget: string
}

type TmuxResult = {
  ok: boolean
  stdout: string
  stderr: string
  exitCode: number
}

function formatPaneList(sessionID: string, panes: PaneInfo[]): string {
  if (panes.length === 0) {
    return [
      "No tmux panes found.",
      "Start a tmux session first, then run /tmux-panes again.",
    ].join("\n")
  }

  const selected = selectedPaneBySession.get(sessionID)
  const lines = ["tmux panes:"]

  panes.forEach((pane, index) => {
    lines.push(
      `${index + 1}. ${pane.target} (${pane.paneID}) [${pane.command || "-"}] cwd=${pane.cwd || "-"} title=${pane.title || "-"}`,
    )
  })

  if (selected) {
    lines.push("")
    lines.push(`Current selected pane: ${selected}`)
  }

  lines.push("")
  lines.push("Select with: /tmux-pane <index|%pane_id|target>")
  lines.push("Use in prompts: `@pane` or `@pane:<target>`")

  return lines.join("\n")
}

function formatHelpMessage(): string {
  return [
    "tmux plugin help",
    "",
    "Commands:",
    "- /tmux-panes",
    "- /tmux-pane <index|%pane_id|target>",
    "- /tmux-help",
    "",
    "Prompt references:",
    "- `@pane` uses selected pane for this OpenCode session",
    "- `@pane:<target>` uses explicit pane target",
    "- expansion only happens for standalone tokens separated by whitespace",
    "",
    "Valid targets:",
    "- numeric index from `/tmux-panes`",
    "- pane id like `%367`",
    "- tmux target like `Work:3.1` or `Work:opencode.1`",
  ].join("\n")
}

async function sendNoReplyMessage(client: any, sessionID: string, text: string) {
  await client.session.prompt({
    path: { id: sessionID },
    body: {
      noReply: true,
      parts: [{ type: "text", text }],
    },
  })
}

async function expandPaneReferencesInText(
  sessionID: string,
  text: string,
  cache: Map<string, Promise<string>>,
  resolvePane: (sessionID: string, selector?: string) => Promise<{ target: string; namedTarget: string; paneID: string } | { error: string }>,
  capturePaneText: (target: string, lines?: number) => Promise<{ output?: string; error?: string }>,
): Promise<string> {
  const regex = /(?<!\S)@pane(?::([^\s`'",;!?()[\]{}<>]+))?(?!\S)/g
  let result = ""
  let cursor = 0

  for (const match of text.matchAll(regex)) {
    const token = match[0]
    const selector = match[1]
    const start = match.index ?? 0

    result += text.slice(cursor, start)

    const cacheKey = selector ? `explicit:${selector}` : `selected:${sessionID}`
    let expansion = cache.get(cacheKey)

    if (!expansion) {
      expansion = (async () => {
        const resolved = await resolvePane(sessionID, selector)
        if ("error" in resolved) {
          throw new Error(`${token} failed: ${resolved.error}`)
        }

        const captured = await capturePaneText(resolved.target)
        if (captured.error) {
          throw new Error(`${token} failed: ${captured.error}`)
        }

        const body = (captured.output ?? "").trim() || "(pane output is empty)"
        return [
          "<tmux-pane>",
          `target: ${resolved.target}`,
          `pane_id: ${resolved.paneID}`,
          `alias: ${resolved.namedTarget}`,
          `lines: ${DEFAULT_CAPTURE_LINES}`,
          body,
          "</tmux-pane>",
        ].join("\n")
      })()

      cache.set(cacheKey, expansion)
    }

    result += await expansion
    cursor = start + token.length
  }

  if (cursor === 0) return text
  result += text.slice(cursor)
  return result
}

export const TmuxPlugin: Plugin = async ({ client, $ }) => {
  async function runTmux(args: string[]): Promise<TmuxResult> {
    const command = `tmux ${args.map((arg) => $.escape(arg)).join(" ")}`

    try {
      const output = await $`${{ raw: command }}`.quiet().nothrow()
      return {
        ok: output.exitCode === 0,
        stdout: output.stdout.toString().trimEnd(),
        stderr: output.stderr.toString().trim(),
        exitCode: output.exitCode,
      }
    } catch (error) {
      return {
        ok: false,
        stdout: "",
        stderr: error instanceof Error ? error.message : String(error),
        exitCode: 1,
      }
    }
  }

  async function listPanes(): Promise<{ panes?: PaneInfo[]; error?: string }> {
    const result = await runTmux([
      "list-panes",
      "-a",
      "-F",
      "#{session_name}\t#{window_index}\t#{window_name}\t#{pane_index}\t#{pane_id}\t#{pane_current_command}\t#{pane_current_path}\t#{pane_title}",
    ])

    if (!result.ok) {
      return {
        error: result.stderr || "tmux list-panes failed",
      }
    }

    const panes: PaneInfo[] = []
    const lines = result.stdout.split("\n").filter(Boolean)

    for (const line of lines) {
      const [session, windowIndex, windowName, paneIndex, paneID, command, cwd, ...titleParts] = line.split("\t")
      if (!session || !windowIndex || !windowName || !paneIndex || !paneID) continue

      const title = titleParts.join("\t")
      const target = `${session}:${windowIndex}.${paneIndex}`
      const namedTarget = `${session}:${windowName}.${paneIndex}`

      panes.push({
        session,
        windowIndex,
        windowName,
        paneIndex,
        paneID,
        command,
        cwd,
        title,
        target,
        namedTarget,
      })
    }

    return { panes }
  }

  async function resolvePane(sessionID: string, selector?: string) {
    const trimmedSelector = selector?.trim()

    let candidate = trimmedSelector
    if (!candidate) {
      candidate = selectedPaneBySession.get(sessionID)
      if (!candidate) {
        return {
          error:
            "No pane selected for @pane. Use /tmux-panes then /tmux-pane <index|%pane_id|target>, or use @pane:<target>.",
        }
      }
    }

    if (/^\d+$/.test(candidate)) {
      const list = await listPanes()
      if (!list.panes) {
        return {
          error: `Failed to list panes: ${list.error}`,
        }
      }

      const index = Number(candidate)
      if (index < 1 || index > list.panes.length) {
        return {
          error: `Pane index out of range: ${candidate}. Use /tmux-panes to see valid indexes.`,
        }
      }

      candidate = list.panes[index - 1].target
    }

    const probe = await runTmux([
      "display-message",
      "-p",
      "-t",
      candidate,
      "#{session_name}\t#{window_index}\t#{window_name}\t#{pane_index}\t#{pane_id}",
    ])

    if (!probe.ok) {
      return {
        error: `Unable to resolve pane target '${candidate}': ${probe.stderr || "invalid target"}`,
      }
    }

    const [session, windowIndex, windowName, paneIndex, paneID] = probe.stdout.split("\t")
    if (!session || !windowIndex || !windowName || !paneIndex || !paneID) {
      return {
        error: `Unable to parse pane metadata for target '${candidate}'.`,
      }
    }

    return {
      target: `${session}:${windowIndex}.${paneIndex}`,
      namedTarget: `${session}:${windowName}.${paneIndex}`,
      paneID,
    }
  }

  async function capturePaneText(target: string, lines = DEFAULT_CAPTURE_LINES) {
    const result = await runTmux(["capture-pane", "-p", "-J", "-t", target, "-S", `-${lines}`])
    if (!result.ok) {
      return {
        error: result.stderr || `tmux capture-pane failed for target '${target}'`,
      }
    }
    return {
      output: result.stdout,
    }
  }

  return {
    config: async (config) => {
      config.command ??= {}

      config.command[COMMAND_LIST_PANES] ??= {
        template: "List all tmux panes and show selection indexes.",
        description: "List tmux panes",
      }

      config.command[COMMAND_SELECT_PANE] ??= {
        template: "Select tmux pane for @pane references: $ARGUMENTS",
        description: "Select tmux pane",
      }

      config.command[COMMAND_HELP] ??= {
        template: "Show tmux plugin usage help.",
        description: "Show tmux help",
      }
    },

    "command.execute.before": async (input) => {
      if (input.command === COMMAND_HELP) {
        await sendNoReplyMessage(client, input.sessionID, formatHelpMessage())
        throw new Error("Command handled by tmux plugin")
      }

      if (input.command === COMMAND_LIST_PANES) {
        const list = await listPanes()
        const message = list.panes
          ? formatPaneList(input.sessionID, list.panes)
          : `Failed to list tmux panes: ${list.error}`

        await sendNoReplyMessage(client, input.sessionID, message)
        throw new Error("Command handled by tmux plugin")
      }

      if (input.command === COMMAND_SELECT_PANE) {
        const selector = input.arguments.trim()
        if (!selector) {
          await sendNoReplyMessage(
            client,
            input.sessionID,
            "Usage: /tmux-pane <index|%pane_id|target>\nRun /tmux-panes to list available panes.",
          )
          throw new Error("Command handled by tmux plugin")
        }

        const resolved = await resolvePane(input.sessionID, selector)
        if ("error" in resolved) {
          await sendNoReplyMessage(client, input.sessionID, resolved.error)
          throw new Error("Command handled by tmux plugin")
        }

        selectedPaneBySession.set(input.sessionID, resolved.target)

        await sendNoReplyMessage(
          client,
          input.sessionID,
          [
            "tmux pane selected for this OpenCode session:",
            `- target: ${resolved.target}`,
            `- pane_id: ${resolved.paneID}`,
            `- alias: ${resolved.namedTarget}`,
            "",
            "You can now reference it with `@pane`.",
          ].join("\n"),
        )

        throw new Error("Command handled by tmux plugin")
      }
    },

    "chat.message": async (input, output) => {
      const cache = new Map<string, Promise<string>>()

      for (const part of output.parts) {
        if (part.type !== "text") continue
        if (!part.text.includes("@pane")) continue

        try {
          part.text = await expandPaneReferencesInText(
            input.sessionID,
            part.text,
            cache,
            (sessionID, selector) => resolvePane(sessionID, selector),
            (target, lines) => capturePaneText(target, lines),
          )
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error)
          throw new Error(`tmux pane expansion blocked this message: ${message}`)
        }
      }
    },

    event: async ({ event }) => {
      if (event.type === "session.deleted") {
        selectedPaneBySession.delete(event.properties.info.id)
      }
    },
  }
}
