return {
  "gnarus-g/restedlang.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "neovim/nvim-lspconfig",
  },
  config = function()
    require("restedlang")
  end,
}