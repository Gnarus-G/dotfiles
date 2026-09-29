local mainMod = "SUPER"
local utils = require("utils")

utils.per_rig_profile("home", function()
  -- Monitors: ultrawide main on top, secondary centered below it
  hl.monitor({
    output = "DP-2",
    mode = "3440x1440@120",
    position = "0x0",
    scale = 1,
  })

  hl.monitor({
    output = "DP-3",
    mode = "1920x1200@60",
    position = "760x1440",
    scale = 1,
  })
end)

hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd('sh "$HOME/.config/hypr/random-wallpaper.sh"')
end)

hl.config({
  animations = { enabled = false },
  input = {
    accel_profile = "flat",
    force_no_accel = true,
  },
})

local scratchpad = require("scratchpad")
scratchpad.setup("Whatever", mainMod .. " + T", 0.5, 0.5)
scratchpad.setup("Work", mainMod .. " + SHIFT + T", 0.8, 0.8)

utils.per_rig_profile("work", function()
  hl.config({
    input = {
      touchpad = {
        natural_scroll = true, -- tweak to taste
        tap_to_click = true,
        disable_while_typing = true,
      },
    },
  })

  -- Todos as a terminal: runs `todo ls` in a named tmux session, then drops to a shell
  scratchpad.setup("Todos", mainMod .. " + Y", 0.5, 0.7, {
    command = "ghostty --gtk-single-instance=false --title=Todos --title-report=false -e tmux new-session -As Todos 'todo ls; exec $SHELL'",
  })
end)

utils.per_rig_profile("home", function()
  -- Todos as the Mynd PWA window (same app LeftWM launches)
  scratchpad.setup("Todos", mainMod .. " + Y", 0.5, 0.7, {
    command = "chromium --profile-directory=Default --app-id=hcenedefeplinmokonjlppanijfggjja",
    class = "crx_hcenedefeplinmokonjlppanijfggjja",
  })
end)

hl.window_rule({
  name = "picture-in-picture",
  match = { title = "^Picture-in-Picture$" },
  float = false,
})

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind("ALT + Up", hl.dsp.focus({ direction = "up" }))
hl.bind("ALT + Down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + Print",
  hl.dsp.exec_cmd(
    'file="$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S.png)"; mkdir -p "$HOME/Pictures/Screenshots" && grim "$file" && "$HOME/.local/bin/wl-copy" --type image/png < "$file"'))
hl.bind(mainMod .. " + SHIFT + S",
  hl.dsp.exec_cmd(
    'file="$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S.png)"; mkdir -p "$HOME/Pictures/Screenshots" && grim -g "$(slurp)" "$file" && "$HOME/.local/bin/wl-copy" --type image/png < "$file"'))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("/usr/bin/sg video -c 'brightnessctl set 5%-'"), { repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("/usr/bin/sg video -c 'brightnessctl set +5%'"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exit())

for i = 1, 9 do
  hl.workspace_rule({ workspace = tostring(i), persistent = true })
  hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = false }))
end
