local wezterm = require("wezterm")
local act = wezterm.action

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
  return string.gsub(s, '(.*)[/\\](.*)$', '%2');
end

wezterm.on(
  'format-tab-title',
  function(tab, tabs, panes, config, hover, max_width)
    local title = basename(tab.active_pane.current_working_dir);
    if title == "" then
      title = tab.active_pane.title
    end
    return "|" .. tab.tab_index + 1 .. "|" .. title .. "  ";
  end
)

return {
  enable_tab_bar = true,
  hide_tab_bar_if_only_one_tab = true,
  tab_bar_at_bottom = true,
  use_fancy_tab_bar = false,
  font = wezterm.font "Fira Code",
  font_size = 10,
  harfbuzz_features = { "zero", "ss01", "cv05" },
  color_scheme = "tokyonight",
  window_background_opacity = 0.88,
  initial_cols = 140,
  initial_rows = 50,
  keys = {
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
    },
    {
      key = 'w',
      mods = 'CTRL|SHIFT',
      action = act.CloseCurrentPane { confirm = true },
    }
  },
  -- This causes `wezterm` to act as though it was started as
  -- `wezterm connect unix` by default, connecting to the unix
  -- domain on startup.
  -- If you prefer to connect manually, leave out this line.
  default_gui_startup_args = { 'connect', 'unix' },
}
