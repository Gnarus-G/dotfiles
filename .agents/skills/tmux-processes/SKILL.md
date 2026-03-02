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

Target syntax: `session:window.pane` (e.g. `dev:0.1`, `work:editor.0`)

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
tmux send-keys -t dev:0.1 'npm run build' Enter

# Send Ctrl+C to stop a process
tmux send-keys -t dev:0.1 C-c

# Send Ctrl+C then start a new command
tmux send-keys -t dev:0.1 C-c && sleep 0.5 && tmux send-keys -t dev:0.1 'npm run dev' Enter
```

### Capture and read pane output

```bash
# Capture last 100 lines from a pane
tmux capture-pane -p -J -t dev:0.1 -S -100

# Capture entire scrollback
tmux capture-pane -p -J -t dev:0.1 -S -

# Capture and search for errors
tmux capture-pane -p -J -t dev:0.1 -S -200 | grep -i 'error\|fail\|panic'
```

### Manage panes

```bash
# Kill a pane
tmux kill-pane -t dev:0.1

# Swap panes
tmux swap-pane -s dev:0.1 -t dev:0.2

# Resize pane (left/down/up/right by N cells)
tmux resize-pane -t dev:0.1 -L 20
tmux resize-pane -t dev:0.1 -D 10

# Zoom/unzoom a pane (toggle fullscreen)
tmux resize-pane -t dev:0.1 -Z
```

### Manage sessions and windows

```bash
# New detached session
tmux new-session -d -s myproject

# Kill session
tmux kill-session -t myproject

# Rename window
tmux rename-window -t dev:0 editor

# Move window
tmux move-window -s dev:2 -t staging:
```

### Wait for a process to finish

```bash
# Check if pane is still running a command (vs idle shell)
tmux display-message -p -t dev:0.1 '#{pane_current_command}'

# Wait-and-capture pattern: poll until process exits
while [ "$(tmux display-message -p -t dev:0.1 '#{pane_current_command}')" != "zsh" ]; do sleep 2; done
tmux capture-pane -p -J -t dev:0.1 -S -50
```

## Workflow Patterns

### Pattern: Dev server + watcher

```bash
tmux new-session -d -s dev -n server
tmux send-keys -t dev:server 'npm run dev' Enter
tmux new-window -t dev -n test
tmux send-keys -t dev:test 'npm run test:watch' Enter
```

### Pattern: Run build and check result

```bash
# Start build in a new pane
tmux split-window -d -h 'npm run build 2>&1; echo "EXIT:$?"'

# Later, capture output to check
tmux capture-pane -p -J -t dev:0.1 -S -50
```

### Pattern: Restart a process

```bash
tmux send-keys -t dev:server C-c
sleep 0.5
tmux send-keys -t dev:server 'npm run dev' Enter
```

## Tips

- Use `-d` flag to create panes/windows/sessions without switching to them
- Always quote commands with spaces in `send-keys`
- Use `Enter` (capital E) as a key name, not `\n`
- `capture-pane -J` joins wrapped lines for cleaner output
- `-S -N` captures last N lines; `-S -` captures full scrollback
- Check `#{pane_current_command}` to see if a process is still running vs shell idle
