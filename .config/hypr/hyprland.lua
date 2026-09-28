local mainMod = "SUPER"

hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
end)

hl.config({ animations = { enabled = false } })

local scratchpad = require("scratchpad")
scratchpad.setup("Whatever", mainMod .. " + T", 0.5, 0.5)
scratchpad.setup("Work", mainMod .. " + SHIFT + T", 0.8, 0.8)

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
