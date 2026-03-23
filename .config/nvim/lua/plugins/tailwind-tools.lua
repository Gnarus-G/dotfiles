return {
  "luckasRanarison/tailwind-tools.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/telescope.nvim",
    "hrsh7th/nvim-cmp",
  },
  config = function()
    local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

    -- Configure tailwindcss LSP directly for nvim 0.11+
    -- (nvim-lspconfig v3.0.0 deprecated the old API)
    vim.lsp.config('tailwindcss', {
      cmd = { 'tailwindcss-language-server', '--stdio' },
      root_markers = {
        'tailwind.config.{js,cjs,mjs,ts}',
        'postcss.config.{js,cjs,mjs,ts}',
        'package.json',
      },
      capabilities = lsp_capabilities,
      settings = {
        tailwindCSS = {
          classAttributes = { "class", "className", "ngClass", "class:list", "classes" },
          classFunctions = { "cva", "cx" },
          experimental = {
            classRegex = {
              { "className\\: '([^']*)'" },
            },
          },
        },
      },
    })

    require("tailwind-tools").setup(
      {
        document_color = {
          enabled = true, -- can be toggled by commands
          kind = "inline", -- "inline" | "foreground" | "background"
          inline_symbol = "󰝤 ", -- only used in inline mode
          debounce = 200, -- in milliseconds, only applied in insert mode
        },
        conceal = {
          enabled = false,
          symbol = "󱏿", -- only a single character is allowed
          highlight = { -- extmark highlight options, see :h 'highlight'
            fg = "#38BDF8",
          },
        },
        server = {
          override = false, -- Don't use lspconfig, we configured vim.lsp.config above
        },
        cmp = {
          highlight = "foreground",
        },
        telescope = {
          utilities = {
            callback = function(_name, _css) end,
          },
        },
        extension = {
          queries = {},
          patterns = {},
        },
        keymaps = {},
      })
  end,
}

