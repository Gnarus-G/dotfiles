local wezterm = require("wezterm")

return {
  enable_tab_bar = false,
  font = wezterm.font "Fira Code",
  font_size = 10,
  harfbuzz_features = { "zero", "ss01", "cv05" },
  color_scheme = "tokyonight",
  window_background_opacity = 0.88,
  initial_cols = 140,
  initial_rows = 50,
}
