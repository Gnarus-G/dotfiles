return {
  "goolord/alpha-nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VimEnter",
  keys = {
    { "<leader>d", "<cmd>Alpha<CR>", desc = "Dashboard" },
  },
  config = function()
    local alpha = require('alpha')

    local my_header = {
      type = "text",
      val = {
        [[ ██████╗ ███╗   ██╗ █████╗ ██████╗ ██╗   ██╗███████╗]],
        [[██╔════╝ ████╗  ██║██╔══██╗██╔══██╗██║   ██║██╔════╝]],
        [[██║  ███╗██╔██╗ ██║███████║██████╔╝██║   ██║███████╗]],
        [[██║   ██║██║╚██╗██║██╔══██║██╔══██╗██║   ██║╚════██║]],
        [[╚██████╔╝██║ ╚████║██║  ██║██║  ██║╚██████╔╝███████║]],
        [[ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝]],
      },
      opts = {
        position = "center",
        hl = "Type",
      },
    }

    local dashboard = require 'alpha.themes.dashboard'

    local my_buttons = {
      type = "group",
      val = {
        { type = "text",    val = "Quick links", opts = { hl = "SpecialComment", position = "center" } },
        { type = "padding", val = 1 },
        dashboard.button("e", "  New file", "<cmd>ene<CR>"),
        dashboard.button("SPC f f", "  Find file"),
        dashboard.button("SPC f g", "  Live grep"),
        dashboard.button("c", "  Configuration", "<cmd>e ~/.config/nvim/init.lua <CR>"),
        dashboard.button("u", "  Update plugins", "<cmd>Lazy sync<CR>"),
        dashboard.button("q", "  Quit", "<cmd>qa<CR>"),
      },
      position = "center",
    }

    local config = require 'alpha.themes.theta'.config

    config.layout[2] = my_header
    config.layout[6] = my_buttons

    alpha.setup(config)
  end,
}
