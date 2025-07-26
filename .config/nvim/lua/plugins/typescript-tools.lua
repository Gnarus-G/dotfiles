return {
  {
    "pmizio/typescript-tools.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
      {
        "dmmulroy/ts-error-translator.nvim",
        dependencies = {
          "pmizio/typescript-tools.nvim",
        },
        config = function()
          require("ts-error-translator").setup()
        end
      }
    },
    opts = {},
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  },
}
