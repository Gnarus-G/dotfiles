local nvim_lsp = require("lspconfig");

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
  vim.keymap.set({ 'n', 'v' }, '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)

  vim.keymap.set('n', '<leader>lr', vim.lsp.codelens.run, { buffer = bufnr, remap = false })
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

require('mason').setup({
  PATH = "append"
})

require 'lspconfig'.ocamllsp.setup {
  capabilities = lsp_capabilities,
}

require('mason-lspconfig').setup({
  automatic_installation = false,
  ensure_installed = { 'rust_analyzer', 'ts_ls', 'dockerls', "cssls", "clangd", "lua_ls", "jsonls" },
  handlers = {
    default_setup,
    lua_ls = function()
      nvim_lsp.lua_ls.setup({
        capabilities = lsp_capabilities,
        settings = {
          Lua = {
            runtime = {
              version = 'LuaJIT',
            },
            diagnostics = {
              globals = { 'vim' },
            },
            workspace = {
              library = {
                vim.env.VIMRUNTIME,
                vim.fn.expand "~/.local/share/nvim/site/pack/packer/start/"
              }
            }
          }
        }
      })
    end,
    ts_ls = function()
      require("typescript-tools").setup {
        settings = {
          code_lens = "references_only",
          -- by default code lenses are displayed on all referencable values and for some of you it can
          -- be too much this option reduce count of them by removing member references from lenses
          disable_member_code_lens = true,
          tsserver_file_preferences = {
            includeInlayParameterNameHints = "all",
          },
        }
      }
    end,
    rust_analyzer = function()
      nvim_lsp.rust_analyzer.setup({
        capabilities = lsp_capabilities,
        settings = {
          ['rust-analyzer'] = {
            checkOnSave = {
              command = "clippy",
            },
            rustfmt = {
              overrideCommand = { "rustfmt", "+nightly", "--edition", "2021" },
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
          { "cva\\(([^)]*)\\)",       "[\"'`]([^\"'`]*).*?[\"'`]" },
          { "cx\\(([^)]*)\\)",        "(?:'|\"|`)([^']*)(?:'|\"|`)" },
          { "classes=\\{([^}]*)\\}",  "[\"'`]([^\"'`]*).*?[\"'`]" },
          { "className\\: '([^']*)'", } -- https://github.com/tailwindlabs/tailwindcss/issues/7553
        },
      },
    },
  },
})

vim.diagnostic.config({
  virtual_text = true,
})

local configs = require 'lspconfig.configs'

-- Rested LSP setup
nvim_lsp.rstdls.setup({
  capabilities = lsp_capabilities
})

-- cnls setup
if not configs.cnls then
  configs.cnls = {
    default_config = {
      cmd = { "cnls" },
      --[[ cmd = { "cargo", "run", "--manifest-path=/home/gnarus/d/cnls/Cargo.toml" }, ]]
      filetypes = { "ocaml", "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" }
    },
  }
end

nvim_lsp.cnls.setup({
  root_dir = nvim_lsp.util.root_pattern("package.json"),
  capabilities = lsp_capabilities,
  settings = {
    cnls = {
      scopes = { "att:className,class,classes,*ClassName", "fn:createElement,cva", "prop:className" }
    }
  }
})

-- todols setup
if not configs.todols then
  configs.todols = {
    default_config = {
      cmd = { "todo", "lsp" },
      filetypes = { "todolang" },
    },
  }
end

nvim_lsp.todols.setup({
  on_attach = on_attach,
  single_file_support = true,
  capabilities = lsp_capabilities
})


--[[ vim.lsp.set_log_level("debug"); ]]
--[[ require('vim.lsp.log').set_format_func(vim.inspect) ]]
