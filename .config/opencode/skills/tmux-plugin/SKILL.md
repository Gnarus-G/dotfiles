---
name: tmux-processes
description: Use the tmux plugin workflow for pane selection, '@pane' references, and long-lived process management.
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

- Use tmux for dev servers, watchers, database processes, and anything expected to outlive the conversation.
- Use regular shell commands for one-shot tasks (build, lint, short commands).

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
