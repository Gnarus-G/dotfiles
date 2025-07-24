return {
  "nvimtools/none-ls.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local null_ls = require("null-ls")
    
    null_ls.setup({
      should_attach = function(bufnr)
        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        local excluded = buf_name:match("^fugitive://") or buf_name:match("NvimTree")
        return not excluded
      end,
      sources = {
        null_ls.builtins.formatting.prettierd.with({
          extra_filetypes = { "astro" },
        }),
        null_ls.builtins.code_actions.gitsigns,
      },
    })
  end,
}