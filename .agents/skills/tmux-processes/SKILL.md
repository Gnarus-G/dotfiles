---
name: tmux-processes
description: "CLI for tmux - manage sessions, windows, panes, and long-running processes. Use when running background builds, dev servers, watchers, or any task that needs monitoring in a separate pane."
---

# tmux Process Management

## What I do

- Run commands in tmux panes so they persist independently of the AI session
- Monitor long-running processes (builds, dev servers, test watchers, deployments)
- Capture and read pane output to check on process status
- Manage sessions, windows, and panes for organized workflows

## When to use me

Use this when you need to:

- Start a dev server, build, or watcher that should keep running
- Run a long command and check its output later
- Organize multiple processes across panes/windows
- Send keys or commands to an existing pane
- Capture terminal output from a running process

## Core Concepts

tmux hierarchy: **session > window > pane**

- **Session**: top-level container, survives disconnects
- **Window**: a tab within a session, holds one or more panes
- **Pane**: a terminal split within a window

Target syntax: `session:window.pane` (e.g. `dev:1.2`, `Work:editor.1`).

## My tmux config notes (gpakosz/.tmux)

The user runs the [oh-my-tmux](https://github.com/gpakosz/.tmux) base config. Behaviors that affect scripted automation:

- **`base-index 1`, `pane-base-index 1`** — windows and panes start at **1**, not 0.
- **`renumber-windows on`** — when a window is killed, remaining windows are renumbered to close the gap. **Address windows by name (`Work:build`) rather than index (`Work:3`)** in any script that may outlive a `kill-window`, since indices shift.
- **`automatic-rename on`** — window titles auto-update to the running command. Passing `-n <name>` to `new-window` locks the name; otherwise `-n build` may drift to `node`, `cargo`, etc. Always pass `-n` if you plan to target by name later.
- **`history-limit 5000`** — `capture-pane -S -` returns at most 5000 lines per pane. For long-running builds, capture incrementally rather than waiting and grabbing the full scrollback.
- **Prefix is `C-b` *and* `C-a`** (GNU-Screen compatible via `prefix2`). Irrelevant for scripted `tmux` calls but worth knowing if sending literal prefix sequences via `send-keys`.
- **`escape-time 10`** — safe to send `Escape` immediately after other keys with `send-keys`.
- **mouse mode is off by default** (commented out in `.tmux.conf.local`); don't assume mouse interaction works.

## My setup (leftwm scratchpads)

Two tmux sessions are bound to leftwm scratchpads via `ghostty -e tmux new-session -As <name>`:

- **`Whatever`** — toggled with `Mod4+t`, general-purpose pad
- **`Work`** — toggled with `Mod4+Shift+t`, larger pad (80% screen) for active work

Because scratchpads use `new-session -As`, the sessions persist across toggles — closing the pad does not kill the session, so long-running processes stay alive. Prefer attaching to these existing sessions over creating new top-level ones, so the user can pull them up with the keybinding.

```bash
# Run a build inside the Work scratchpad session, in a new window
tmux new-window -t Work: -n build 'cargo build --release'

# Send a command to the Whatever session's first window
tmux send-keys -t Whatever:1 'tail -f /var/log/syslog' Enter

# Capture output from a pane inside Work
tmux capture-pane -p -J -t Work:build -S -100
```

If neither session exists yet, create it detached so the scratchpad keybinding can later attach:

```bash
tmux new-session -d -s Work
```

## Essential Commands

### List what's running

```bash
# List sessions
tmux list-sessions

# List all panes with details
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} [#{pane_current_command}] #{pane_current_path}'

# List windows in current session
tmux list-windows
```

### Run a command in a new pane

```bash
# Split current window horizontally and run command
tmux split-window -h 'npm run dev'

# Split vertically
tmux split-window -v 'cargo watch -x test'

# New window with command
tmux new-window -n server 'python manage.py runserver'

# New session with command
tmux new-session -d -s build 'make all'
```

### Send commands to an existing pane

```bash
# Send keys to a target pane
tmux send-keys -t dev:1.2 'npm run build' Enter

# Send Ctrl+C to stop a process
tmux send-keys -t dev:1.2 C-c

# Send Ctrl+C then start a new command
tmux send-keys -t dev:1.2 C-c && sleep 0.5 && tmux send-keys -t dev:1.2 'npm run dev' Enter
```

### Capture and read pane output

```bash
# Capture last 100 lines from a pane
tmux capture-pane -p -J -t dev:1.2 -S -100

# Capture entire scrollback
tmux capture-pane -p -J -t dev:1.2 -S -

# Capture and search for errors
tmux capture-pane -p -J -t dev:1.2 -S -200 | grep -i 'error\|fail\|panic'
```

### Manage panes

```bash
# Kill a pane
tmux kill-pane -t dev:1.2

# Swap panes
tmux swap-pane -s dev:1.2 -t dev:1.3

# Resize pane (left/down/up/right by N cells)
tmux resize-pane -t dev:1.2 -L 20
tmux resize-pane -t dev:1.2 -D 10

# Zoom/unzoom a pane (toggle fullscreen)
tmux resize-pane -t dev:1.2 -Z
```

### Manage sessions and windows

```bash
# New detached session
tmux new-session -d -s myproject

# Kill session
tmux kill-session -t myproject

# Rename window
tmux rename-window -t dev:1 editor

# Move window
tmux move-window -s dev:2 -t staging:
```

### Wait for a process to finish

```bash
# Check if pane is still running a command (vs idle shell)
tmux display-message -p -t dev:1.2 '#{pane_current_command}'

# Wait-and-capture pattern: poll until process exits
while [ "$(tmux display-message -p -t dev:1.2 '#{pane_current_command}')" != "zsh" ]; do sleep 2; done
tmux capture-pane -p -J -t dev:1.2 -S -50
```

## Workflow Patterns

### Pattern: Dev server + watcher inside the Work scratchpad

```bash
# Ensure session exists, then add windows for server + watcher
tmux has-session -t Work 2>/dev/null || tmux new-session -d -s Work
tmux new-window -t Work: -n server 'npm run dev'
tmux new-window -t Work: -n test 'npm run test:watch'
# User pulls it up with Mod4+Shift+t
```

### Pattern: Run build and check result

```bash
# Start build in a new window of the Work session
tmux new-window -t Work: -n build 'npm run build 2>&1; echo "EXIT:$?"'

# Later, capture output to check
tmux capture-pane -p -J -t Work:build -S -50
```

### Pattern: Restart a process

```bash
tmux send-keys -t Work:server C-c
sleep 0.5
tmux send-keys -t Work:server 'npm run dev' Enter
```

## Tips

- Use `-d` flag to create panes/windows/sessions without switching to them
- Always quote commands with spaces in `send-keys`
- Use `Enter` (capital E) as a key name, not `\n`
- `capture-pane -J` joins wrapped lines for cleaner output
- `-S -N` captures last N lines; `-S -` captures full scrollback
- Check `#{pane_current_command}` to see if a process is still running vs shell idle
