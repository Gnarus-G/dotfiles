local wezterm = require("wezterm")
local act = wezterm.action

wezterm.on('update-right-status', function(window, pane)
  window:set_right_status(window:active_workspace())
end)


return {
  enable_tab_bar = true,
  font = wezterm.font "Fira Code",
  font_size = 10,
  harfbuzz_features = { "zero", "ss01", "cv05" },
  color_scheme = "tokyonight",
  window_background_opacity = 0.88,
  initial_cols = 140,
  initial_rows = 50,
  keys = {
    -- Switch to the default workspace
    {
      key = 'y',
      mods = 'CTRL|SHIFT',
      action = act.SwitchToWorkspace {
        name = 'default',
      },
    },
    -- Switch to a monitoring workspace, which will have `top` launched into it
    {
      key = 'd',
      mods = 'CTRL|SHIFT',
      action = act.SwitchToWorkspace {
        name = 'Dev',
        spawn = {
          args = { 'nvim' },
          cwd = '/home/gnarus/d'
        },
      },
    },
    -- Create a new workspace with a random name and switch to it
    { key = 'i', mods = 'CTRL|SHIFT', action = act.SwitchToWorkspace },
    -- Show the launcher in fuzzy selection mode and have it list all workspaces
    -- and allow activating one.
    {
      key = 'd',
      mods = 'ALT',
      action = act.ShowLauncherArgs {
        flags = 'FUZZY|WORKSPACES',
      },
    },
  },
}
