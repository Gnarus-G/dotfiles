local cmp = require("cmp")
local compare = cmp.config.compare

cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<HOME>'] = function(fallback)
      if cmp.visible() then
        local selected_entry = cmp.get_selected_entry()
        local entries = cmp.get_entries()
        -- Check if entries exist and if the selected entry is NOT the first one
        if not selected_entry or #entries == 0 or selected_entry ~= entries[1] then
          -- Select the previous item many times to ensure we are at the top
          cmp.select_prev_item({ count = math.huge, behavior = cmp.SelectBehavior.Select })
        end
      else
        fallback()
      end
    end,
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  sources = cmp.config.sources({
    { name = 'minuet' },
    { name = "nvim_lsp" },
    { name = "nvim_lua" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
  }),
  performance = {
    fetching_timeout = 2000, -- for LLM responses by minuet
  },
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  formatting = {
    format = require("lspkind").cmp_format({
      menu = {
        nvim_lsp = "[lsp]",
        nvim_lua = "[lua]",
        minuet = "[minuet]",
        luasnip = "[luasnip]",
        npm = "[npm]",
        buffer = "[buf]",
        path = "[path]",
        cmdline = "[cmd]",
      },
      before = require("tailwind-tools.cmp").lspkind_format
    })
  },
  sorting = {
    priority_weight = 1.0,
    comparators = {
      compare.score, -- Jupyter kernel completion shows prior to LSP
      compare.recently_used,
      compare.locality,
      -- ...
    },
  },
})

-- Setup cmp sources specifically for json files (e.g., package.json)
require('cmp-npm').setup({})
cmp.setup.filetype('json', {
  sources = cmp.config.sources({
    { name = 'npm', keyword_length = 4 } -- Enable npm source for json
  }, {
    { name = 'nvim_lsp' },               -- Keep LSP suggestions (jsonls)
    { name = 'buffer' },                 -- Keep buffer suggestions
    { name = 'path' }                    -- Keep path suggestions
  })
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' },
  }, {
    { name = 'cmdline' }
  }),
  matching = { disallow_symbol_nonprefix_matching = false }
})
