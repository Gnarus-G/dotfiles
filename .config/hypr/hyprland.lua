local mainMod = "SUPER"

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
end)

hl.config({ animations = { enabled = false } })

local scratchpad = require("scratchpad")
scratchpad.setup("Whatever", mainMod .. " + T", 0.5, 0.5)
scratchpad.setup("Work", mainMod .. " + SHIFT + T", 0.8, 0.8)

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind("ALT + Up", hl.dsp.focus({ direction = "up" }))
hl.bind("ALT + Down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exit())

for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true })
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i, follow = false }))
end
