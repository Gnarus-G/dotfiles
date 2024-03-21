local nvim_lsp = require("lspconfig");

local cmp = require("cmp");
require('cmp-npm').setup({})
cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
    ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
    ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
    ["<C-e>"] = cmp.mapping({
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    }),
    -- Accept currently selected item. If none selected, `select` first item.
    -- Set `select` to `false` to only confirm explicitly selected items.
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  sources = cmp.config.sources({
    { name = "npm",     keyword_length = 4 },
    { name = "nvim_lsp" },
    { name = "nvim_lua" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
  }),
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  formatting = {
    format = require("lspkind").cmp_format({
      before = require("tailwind-tools.cmp").lspkind_format
    })
  }
})

-- note: diagnostics are not exclusive to lsp servers
-- so these can be global keybindings
vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>')
vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')
vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')

--
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, remap = false }

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  vim.keymap.set('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  vim.keymap.set('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  vim.keymap.set('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  vim.keymap.set('n', '<leader>wl',
    '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  vim.keymap.set('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.keymap.set('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
end

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    on_attach(nil, event.buf)
  end
})

local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

local default_setup = function(server)
  require('lspconfig')[server].setup({
    capabilities = lsp_capabilities,
  })
end

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = { 'rust_analyzer', 'tsserver', 'dockerls', "cssls", "clangd", "lua_ls", "jsonls" },
  handlers = {
    default_setup,
    lua_ls = function()
      nvim_lsp.lua_ls.setup({
        capabilities = lsp_capabilities,
        settings = {
          Lua = {
            runtime = {
              version = 'LuaJIT'
            },
            diagnostics = {
              globals = { 'vim' },
            },
            workspace = {
              library = {
                vim.env.VIMRUNTIME,
              }
            }
          }
        }
      })
    end,
    tsserver = function()
      require("typescript").setup({
        disable_commands = false, -- prevent the plugin from creating Vim commands
        debug = false,            -- enable debug logging for commands
        go_to_source_definition = {
          fallback = true,        -- fall back to standard LSP definition on failure
        },
        server = {
          root_dir = nvim_lsp.util.root_pattern("package.json"),
          single_file_support = false,
          capabilities = lsp_capabilities
        }
      })
    end,
    rust_analyzer = function()
      nvim_lsp.rust_analyzer.setup({
        capabilities = lsp_capabilities,
        settings = {
          ['rust-analyzer'] = {
            diagnostics = {
              disabled = {
                "needless_return",
              },
            },
            checkOnSave = {
              command = "clippy",
              extraArgs = { "--", "-A", "clippy::new_without_default", "-A", "clippy::needless_return" }
            }
          }
        }
      })
    end,
    jsonls = function()
      nvim_lsp.jsonls.setup({
        settings = {
          json = {
            schemas = require "schemastore".json.schemas(),
            validate = { enable = true }
          }
        }
      })
    end,
    denols = function()
      nvim_lsp.denols.setup({
        root_dir = nvim_lsp.util.root_pattern("deno.json", "deno.jsonc"),
      })
    end
  },
})

-- npm install -g @tailwindcss/language-server
nvim_lsp.tailwindcss.setup({
  settings = {
    tailwindCSS = {
      experimental = {
        classRegex = {
          { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
          { "cx\\(([^)]*)\\)",  "(?:'|\"|`)([^']*)(?:'|\"|`)" }
        },
      },
    },
  },
})

vim.diagnostic.config({
  virtual_text = true,
})

-- Rested LSP setup
local configs = require 'lspconfig.configs'

if not configs.rstdls then
  configs.rstdls = {
    default_config = {
      cmd = { "rstd", "lsp" },
      filetypes = { "rd" },
    },
  }
end

nvim_lsp.rstdls.setup({
  single_file_support = true,
  capabilities = lsp_capabilities
})

-- cnls setup
if not configs.cnls then
  configs.cnls = {
    default_config = {
      cmd = { "cnls" },
      --[[ cmd = { "cargo", "run", "--manifest-path=/home/gnarus/d/cnls/Cargo.toml" }, ]]
      filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" }
    },
  }
end

nvim_lsp.cnls.setup({
  root_dir = nvim_lsp.util.root_pattern("package.json"),
  capabilities = lsp_capabilities,
  settings = {
    cnls = {
      scopes = { "att:className,class", "fn:createElement" }
    }
  }
})


--[[ vim.lsp.set_log_level("debug"); ]]
--[[ require('vim.lsp.log').set_format_func(vim.inspect) ]]
