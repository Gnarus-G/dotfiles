local wezterm = require("wezterm")
local act = wezterm.action

return {
  enable_tab_bar = false,
  -- paru -S ttf-hack-ligatured
  font = wezterm.font "Hack JBM Ligatured",
  font_size = 12,
  harfbuzz_features = { "zero", "ss01", "cv05" },
  color_scheme = "tokyonight",
  window_background_opacity = 0.88,
  initial_cols = 140,
  initial_rows = 50,
  keys = {
    {
      key = 'w',
      mods = 'CTRL|SHIFT',
      action = act.CloseCurrentPane { confirm = true },
    },
    { -- I don't need tabs from wezterm
      key = 't',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.DisableDefaultAssignment,
    },

  },
}
