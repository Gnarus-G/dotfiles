local function stop_clients(exclude, bufnr)
  local active_clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, active_client in ipairs(active_clients) do
    if vim.tbl_contains(exclude, active_client.name) then
      vim.lsp.stop_client(active_client.id)
    end
  end
end

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
      on_attach = function(client, bufnr)
        -- Disable document formatting capabilities, we use prettierd with none-ls
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false

        vim.api.nvim_create_autocmd("LspAttach", {
          desc = 'Stop denols in favor of typescript-tools',
          callback = function(_)
            stop_clients({ "denols" }, bufnr)
          end
        })
      end,
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
