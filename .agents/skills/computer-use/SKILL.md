---
name: computer-use
description: Operate desktop apps through screenshots, clicks, and typing on Linux Wayland. Use when asked for computer use, GUI automation, or a task in an existing desktop app.
compatibility: Linux Wayland desktop with screenshot capture and input tools; includes a tested Hyprland fallback.
---

# Computer use

Drive the visible desktop in a screenshot–action–verify loop.
Use the current app window rather than launching another copy.
If the user requests GUI-only work, use shell commands only to capture screenshots, focus windows, and send input.
Do not substitute an app CLI, API, browser, or file edit for the requested GUI actions.

## Check the desktop

```bash
printenv XDG_CURRENT_DESKTOP WAYLAND_DISPLAY
command -v grim ydotool ydotoold hyprctl
```

Prefer an available computer-use tool that supports this desktop.
Otherwise, use `grim` for screenshots and `ydotool` for input where supported.
`grim` requires compositor support; Wayland alone does not guarantee it.
Spectacle's Wayland capture requires KWin, so use `grim` on Hyprland.
`xdotool` does not control native Wayland windows.

Check the installed input tool's help before sending actions.
Old and new `ydotool` versions use different syntax.
The examples below use Ubuntu's `ydotool` 0.1.8, verified in a desktop session:

```bash
ydotool --help
ydotool key --help
ydotool click --help
ydotool type --help
```

For missing tools or a stopped daemon, follow the [tmux handoff](../tmux-processes/SKILL.md#Command-handoff-in-Whatever).
On Debian or Ubuntu, the installation command is:

```bash
sudo apt-get install -y grim ydotool ydotoold
```

Run `sudo ydotoold` in a dedicated tmux window if no service manages it.
Let the user enter any sudo password there, never in chat.
Check the daemon output and its socket permissions before using the client.
A running process alone does not prove that input works.
If the client reports an unavailable backend or a failure opening `/dev/uinput`, fix access before continuing.
For 0.1.8, the daemon used `/tmp/.ydotool_socket`; its root-only ownership required adjustment for the current user.
Check the actual socket and owner before changing permissions.
Do not grant world access to the socket or `/dev/uinput`.

## See, act, then check

1. Capture the current desktop to a temporary file.
2. Open the image with the image-reading tool.
3. Find the target window and control in that screenshot.
4. Perform one action or a short sequence with known focus.
5. Wait for the UI to settle, then capture and inspect another screenshot.

Use an existing, approved temporary directory for screenshots:

```bash
grim /tmp/opencode/desktop.png
```

Read that file as an image; command success is not visual verification.
Create a temporary directory first if the session has none.
Do not commit screenshots or store private app contents in the skill.

Do not guess coordinates from a resized image.
Convert image coordinates to desktop coordinates using the output's scale.
For example, a 2000-pixel-wide screenshot of a 1920-unit desktop needs a factor of `1920 / 2000`.
Recheck the scale when the display, resolution, or window changes.

### Input with ydotool 0.1.8

```bash
ydotool click 1
ydotool type 'example-value'
ydotool key ctrl+a
ydotool key shift+Tab
ydotool key Tab Tab Tab
ydotool key Enter Home Enter
ydotool key PageDown
```

In this version, `click 1` is a left click and `Enter` activates a control.
`Return` did not activate the tested menu.
Use `ctrl+a` only after confirming focus in a field you may replace.
Quote literal text rather than interpolating it into shell source.

Wait after creating a control before typing into it:

```bash
ydotool key Enter Home Enter && sleep 0.5 && ydotool type 'example-value'
```

Without the wait, the tested editor dropped the start of the value.
Check the full resulting text, including case, punctuation, and leading zeroes.
Batch repeated actions only after screenshots establish the tab order and stable behavior.
Stop the batch when focus or layout differs from that pattern.

### Hyprland fallback for focus and pointer movement

Use this section only on Hyprland.
Inspect window metadata to find the existing app's class:

```bash
hyprctl clients -j
hyprctl cursorpos
```

The Lua-based Hyprland dispatcher used in the tested session supports:

```bash
hyprctl dispatch 'hl.dsp.focus({window = "class:APP_CLASS"})'
hyprctl dispatch 'hl.dsp.cursor.move({x = 450, y = 286})'
ydotool click 1
```

Replace the class and coordinates with values observed in the current session.
Capture a screenshot after focusing the window.
Do not copy this syntax to older Hyprland versions without checking their dispatcher help.
The tested version rejected the older `hyprctl dispatch focuswindow ...` syntax.

Use compositor pointer movement if `ydotool mousemove` moves unpredictably.
Do not calibrate with huge movements; these can trigger desktop gestures or change the active workspace.
Do not guess workspace shortcuts to focus an app.
On another compositor, use its supported focus and pointer controls, or a verified input tool.

## Edit and verify records

- Confirm the app, container, and record before editing.
- If the app is locked, stop and ask the user to unlock it.
- Check existing labels before adding fields; apply the user's duplicate rule.
- Select the requested field type explicitly.
- Preserve existing fields and never reveal or copy concealed values unless the task explicitly requires it.
- Work only with the new controls when adding data.
- Save the record, select another record, then reopen the saved record.
- Find the record by its current title; saving can reorder the list.
- Inspect every new label and value after reopening, scrolling when needed.
- Report only verified results in the requested format.

For a repeated-field editor, establish its keyboard flow on one new field first.
One tested flow focused the value after adding a Text field.
`shift+Tab` reached its label, and three `Tab` presses from the label reached “add another field”.
This is an example to verify in the current app, not a universal tab order.
