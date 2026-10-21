---
name: tmux-processes
description: Use the tmux plugin for pane selection and process monitoring, or start commands the user needs to watch or interact with (sudo, confirmations, prompts) in the Whatever scratchpad.
---

# tmux Process Management (Plugin-First)

This skill is now backed by the local plugin at:

- `.config/opencode/plugins/tmux.ts`

The plugin adds deterministic tmux workflows directly into OpenCode.

## Pane Selection and References

Use these commands:

- `/tmux-panes` to list panes
- `/tmux-pane <index|%pane_id|target>` to select a pane for the current OpenCode session
- `/tmux-help` to show usage and target formats

Then reference panes in prompts:

- `` `@pane` `` uses the selected pane for the current OpenCode session
- `` `@pane:<target>` `` uses an explicit pane target

Supported target styles:

- Numeric index from `/tmux-panes` output
- tmux pane id (for example `%351`)
- tmux target (for example `Work:1.1` or `Work:opencode.1`)

## Long-Lived Process Rules

- Use tmux for dev servers, watchers, database processes, and anything expected to outlive the conversation; use `Whatever` when the user needs to watch or control it.
- Use regular shell commands for one-shot tasks (build, lint, short commands).

## Command handoff in Whatever

If you would otherwise ask the user to run a command, start it yourself in a **fresh shell window** of `Whatever` instead. This includes interactive commands (passwords, confirmations, yes/no prompts) and long-lived commands the user may need to watch or control (dev servers, watchers). The plugin's `@pane` references only read output; use tmux CLI `send-keys` to start the command, never an active agent/process pane.

```bash
tmux has-session -t Whatever 2>/dev/null || tmux new-session -d -s Whatever
PANE=$(tmux new-window -d -P -F '#{pane_id}' -t Whatever: -n dev-server -c "$PWD")
tmux send-keys -t "$PANE" 'npm run dev' Enter
tmux capture-pane -p -J -t "$PANE" -S -20
```

Replace the sample command and window name with the actual ones. Use the returned pane id to avoid targeting an existing window with the same name. Check the output for readiness or a prompt, then tell the user the window name. If their input or attention is needed, call them with `gnarus-tts` when available (for example, `gnarus-tts "Your command is waiting for input in the Whatever dev-server window."`). Let the user answer prompts and enter passwords in the window, never in chat; do not capture the pane while they are typing a secret. After they finish, verify the result and continue; for long-lived commands, verify readiness and leave the window running.

## Recommended tmux Start Pattern

Always run commands inside an interactive shell (send-keys pattern):

```bash
SESSION=$(basename $(git rev-parse --show-toplevel 2>/dev/null) || basename $PWD)

tmux new-session -d -s "$SESSION" -n server
tmux send-keys -t "$SESSION:server" 'npm run dev' Enter
```

Avoid inline `tmux new-session ... '<command>'` when shell init matters.

## Monitoring Output

Use pane references in chat when you want model context from tmux logs:

- "Check this server output: `@pane`"
- "Inspect this pane for errors: `@pane:%351`"

## Isolation Rules

- Never use `tmux kill-server`
- Never kill sessions unrelated to the current project
- Derive session names from project root where possible
