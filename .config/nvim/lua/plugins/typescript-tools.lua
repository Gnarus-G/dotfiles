return {
  "pmizio/typescript-tools.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "neovim/nvim-lspconfig",
    "dmmulroy/ts-error-translator.nvim",
  },
  ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  config = function()
    require("ts-error-translator").setup()
    require("typescript-tools").setup({})
  end,
}

