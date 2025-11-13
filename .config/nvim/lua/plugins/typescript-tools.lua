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
    opts = {
      single_file_support = false,
      root_dir = require('lspconfig.util').root_pattern('package.json', 'tsconfig.json', 'jsconfig.json'),
      settings = {
        expose_as_code_action = "all",
        code_lens = "references_only",
        disable_member_code_lens = true,
      }
    },
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  },
}
