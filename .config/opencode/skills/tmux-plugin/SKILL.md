---
name: tmux-processes
description: Use the tmux plugin for pane references, long-lived processes, and interactive command handoffs in the Whatever scratchpad.
---

# tmux Process Management (Plugin-First)

Plugin: `.config/opencode/plugins/tmux.ts`.

## Pane Selection and References

- `/tmux-panes` or `/tmux-pane` lists panes; `/tmux-pane <index|%id|target>` selects one; `/tmux-help` shows help.
- `@pane` captures the session's selection; `@pane:<target>` captures an explicit pane.
- Targets can be list indexes, pane IDs (`%351`), or tmux targets (`Work:1.1`, `Work:opencode.1`).

## Command handoff in Whatever

Start commands the user needs to run, answer, or watch (including sudo prompts and dev servers) in a fresh `Whatever` window; run short noninteractive commands in the regular shell. `@pane` only reads output; use tmux CLI to start commands.

```bash
tmux has-session -t Whatever 2>/dev/null || tmux new-session -d -s Whatever
PANE=$(tmux new-window -d -P -F '#{pane_id}' -t Whatever: -n dev-server -c "$PWD")
tmux send-keys -t "$PANE" 'npm run dev' Enter
tmux capture-pane -p -J -t "$PANE" -S -20
```

Replace the example command and window name; target the returned pane ID so duplicate window names cannot misdirect commands. Tell the user the window name, without a keybind reminder, and call them with `gnarus-tts` when input is needed. Let them answer prompts in the window, never in chat; avoid capturing secrets while they type. Check the result or readiness afterward and leave long-lived processes running.

Use `send-keys` into a shell as above when shell initialization matters.

## Monitoring Output

Use pane references in chat when you want model context from tmux logs:

- "Check this server output: `@pane`"
- "Inspect this pane for errors: `@pane:%351`"

## Isolation Rules

- Never use `tmux kill-server`
- Never kill sessions unrelated to the current project
- Derive session names from project root where possible
