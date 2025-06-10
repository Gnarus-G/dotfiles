local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

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
      override = true,
      capabilities = lsp_capabilities,
      settings = {
        classAttributes = { "class", "className", "ngClass", "class:list", "classes" },
        classFunctions = { "cva", "cx" },
        experimental = {
          classRegex = {
            --[[ { "cva\\(([^)]*)\\)",       "[\"'`]([^\"'`]*).*?[\"'`]" }, ]]
            --[[ { "cx\\(([^)]*)\\)",        "(?:'|\"|`)([^']*)(?:'|\"|`)" }, ]]
            --[[ { "classes=\\{([^}]*)\\}",  "[\"'`]([^\"'`]*).*?[\"'`]" }, ]]
            { "className\\: '([^']*)'", } -- https://github.com/tailwindlabs/tailwindcss/issues/7553
          },
        },
      }
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
