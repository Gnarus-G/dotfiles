local wezterm = require("wezterm")
local act = wezterm.action

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
---@param s string
---@return string
local function basename(s)
  assert(type(s) == "string");
  local subbed, _ = string.gsub(s, '(.*)[/\\](.*)$', '%2');
  return subbed
end

wezterm.on(
  'format-tab-title',
  function(tab, tabs, panes, config, hover, max_width)
    local cwd = tab.active_pane.current_working_dir.file_path;
    local title = basename(cwd);
    if title == "" then
      title = tab.active_pane.title
    end
    return "|" .. tab.tab_index + 1 .. "| " .. title .. "  ";
  end
)

return {
  enable_tab_bar = true,
  hide_tab_bar_if_only_one_tab = true,
  tab_bar_at_bottom = true,
  use_fancy_tab_bar = false,
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
  },
}
