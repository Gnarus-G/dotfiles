return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
      "onsails/lspkind-nvim",
      "David-Kunz/cmp-npm",
      "rcarriga/cmp-dap",
    },
    config = function()
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
              if not selected_entry or #entries == 0 or selected_entry ~= entries[1] then
                cmp.select_prev_item({ count = math.huge, behavior = cmp.SelectBehavior.Select })
              end
            else
              fallback()
            end
          end,
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = false }),
        }),
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        sources = cmp.config.sources(
          {
            { name = 'minuet' },
            { name = "nvim_lsp" },
            { name = "nvim_lua" },
            { name = "luasnip" },
          },
          {
            {
              name = "buffer",
              option = { get_bufnrs = require "gnarus.utils".get_loaded_buffers }
            },
            { name = "path" },
          }
        ),
        performance = {
          fetching_timeout = 2000,
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
            compare.score,
            compare.recently_used,
            compare.locality,
          },
        },
      })

      -- Setup cmp sources specifically for json files
      require('cmp-npm').setup({})
      cmp.setup.filetype('json', {
        sources = cmp.config.sources({
          { name = 'npm', keyword_length = 4 }
        }, {
          { name = 'nvim_lsp' },
          { name = 'buffer' },
          { name = 'path' }
        })
      })

      -- Use buffer source for `/` and `?`
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

      -- DAP completion
      cmp.setup.filetype({ "dap-repl", "dapui_watches" }, {
        enabled = function()
          local buf = vim.api.nvim_get_current_buf()
          return require("cmp_dap").is_dap_buffer(buf)
        end,
        sources = cmp.config.sources({
          { name = "dap" },
        }),
        formatting = {
          format = require("lspkind").cmp_format({
            menu = {
              dap = "[dap]",
            },
          })
        },
      })
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    build = "make install_jsregexp",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
  {
    "David-Kunz/cmp-npm",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = "json",
  },
}
