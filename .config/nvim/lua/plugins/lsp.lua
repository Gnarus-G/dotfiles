return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "b0o/schemastore.nvim",
    },
    config = function()
      -- Global diagnostic keybindings
      vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>')
      vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')
      vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')

      -- LSP attach function
      local on_attach = function(_, bufnr)
        local opts = { buffer = bufnr, remap = false }

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

      -- LSP server configurations
      vim.lsp.config("ocamllsp", {
        capabilities = lsp_capabilities,
      })

      vim.lsp.config("lua_ls", {
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
                vim.fn.expand "~/.local/share/nvim/lazy/"
              }
            }
          }
        }
      })

      vim.lsp.config("rust_analyzer", {
        capabilities = lsp_capabilities,
        settings = {
          ['rust-analyzer'] = {
            checkOnSave = {
              command = "clippy",
              extraArgs = { "--", "-D", "warnings" },
            },
            rustfmt = {
              overrideCommand = { "rustfmt", "+nightly", "--edition", "2021" },
            }
          }
        }
      })

      vim.lsp.config("jsonls", {
        settings = {
          json = {
            schemas = require "schemastore".json.schemas(),
            validate = { enable = true }
          }
        }
      })

      vim.lsp.config("denols", {
        single_file_support = false,
        root_dir = require('lspconfig.util').root_pattern('deno.json', 'deno.jsonc')
      })

      vim.diagnostic.config({
        virtual_text = {
          severity = { min = vim.diagnostic.severity.WARN },
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      vim.lsp.config("rstdls", {
        capabilities = lsp_capabilities
      })

      vim.lsp.config("tailwindcss", {
        cmd = { "sh", "-c", "NODE_OPTIONS='--max-old-space-size=2048' tailwindcss-language-server --stdio" },
        filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", "vue", "html" },
        root_markers = { "tailwind.config.js", "tailwind.config.ts", "postcss.config.js", "postcss.config.ts", "tailwind.config.mjs", "tailwind.config.mts" },
        capabilities = lsp_capabilities,
      })

      vim.lsp.config("todols", {
        cmd = { "todo", "lsp" },
        filetypes = { "todolang" },
        single_file_support = true,
        capabilities = lsp_capabilities
      })

      vim.lsp.enable { "todols" }
    end,
  },
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    opts = { PATH = "append" },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { 'rust_analyzer', 'dockerls', "cssls", "clangd", "lua_ls", "jsonls" },
      automatic_enable = true
    },
  },
  {
    "b0o/schemastore.nvim",
    lazy = true,
  },
}
