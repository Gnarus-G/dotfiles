local ok, alpha = pcall(require, 'alpha')
if not ok then
  return
end

vim.keymap.set("n", "<leader>d", "<cmd>Alpha<CR>")

local my_header = {
  type = "text",
  val = {
    [[   _____                            ]],
    [[  / ____|                           ]],
    [[ | |  __ _ __   __ _ _ __ _   _ ___ ]],
    [[ | | |_ | '_ \ / _\` | '__| | | / __|]],
    [[ | |__| | | | | (_| | |  | |_| \__ \]],
    [[  \_____|_| |_|\__,_|_|   \__,_|___/]],
    [[                                    ]],
    [[                                    ]]
  },
  opts = {
    position = "center",
    hl = "Type",
    -- wrap = "overflow"
  },
}

local dashboard = require 'alpha.themes.dashboard'

local my_buttons = {
  type = "group",
  val = {
    { type = "text", val = "Quick links", opts = { hl = "SpecialComment", position = "center" } },
    { type = "padding", val = 1 },
    dashboard.button("e", "  New file", "<cmd>ene<CR>"),
    dashboard.button("SPC f f", "  Find file"),
    dashboard.button("SPC f g", "  Live grep"),
    dashboard.button("c", "  Configuration", "<cmd>e ~/.config/nvim/init.lua <CR>"),
    dashboard.button("u", "  Update plugins", "<cmd>PackerSync<CR>"),
    dashboard.button("q", "  Quit", "<cmd>qa<CR>"),
  },
  position = "center",
}

local config = require 'alpha.themes.theta'.config

config.layout[2] = my_header
config.layout[6] = my_buttons

alpha.setup(config)
