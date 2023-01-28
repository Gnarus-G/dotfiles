local wezterm = require("wezterm")
local act = wezterm.action

wezterm.on('update-right-status', function(window, pane)
  window:set_right_status(window:active_workspace())
end)

local launch_menu = {}

local projects_dir = wezterm.home_dir .. "/d/";
-- Find all my git projects under the directory ~/d/
local success, stdout, stderr = wezterm.run_child_process { "fd", "-HIg", "**/.git", "--base-directory", projects_dir,
  "--strip-cwd-prefix", "-x", "echo", "{//}" }

if success then
  for _, line in ipairs(wezterm.split_by_newlines(stdout)) do
    local path = projects_dir .. line;
    table.insert(launch_menu, {
      label = line,
      args = { 'nvim' },
      cwd = path
    })
  end
else
  wezterm.log_error("Couldn't find projects with fd - " .. stderr);
end

return {
  enable_tab_bar = true,
  font = wezterm.font "Fira Code",
  font_size = 10,
  harfbuzz_features = { "zero", "ss01", "cv05" },
  color_scheme = "tokyonight",
  window_background_opacity = 0.88,
  initial_cols = 140,
  initial_rows = 50,
  launch_menu = launch_menu,
  keys = {
    -- Show launcher menu items
    {
      key = 'd',
      mods = 'ALT|SHIFT',
      action = act.ShowLauncherArgs {
        flags = 'FUZZY|LAUNCH_MENU_ITEMS',
        title = "Projects and stuff"
      },
    },
    {
      key = '"',
      mods = 'CTRL|SHIFT',
      action = act.SplitVertical {
        domain = 'CurrentPaneDomain'
      },
    },
    {
      key = '%',
      mods = 'CTRL|SHIFT',
      action = act.SplitHorizontal {
        domain = 'CurrentPaneDomain'
      },
    }
  },
  -- This causes `wezterm` to act as though it was started as
  -- `wezterm connect unix` by default, connecting to the unix
  -- domain on startup.
  -- If you prefer to connect manually, leave out this line.
  default_gui_startup_args = { 'connect', 'unix' },
}
