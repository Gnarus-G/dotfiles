local nvim_lsp = require("lspconfig");
local lsp = require('lsp-zero')

lsp.preset('recommended')

lsp.ensure_installed { 'rust_analyzer', 'tailwindcss', 'dockerls', "cssls", "clangd" }

local cmp = require("cmp");
require('cmp-npm').setup({})
lsp.setup_nvim_cmp({
  mapping = lsp.defaults.cmp_mappings({
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
  sources = {
    { name = "npm",     keyword_length = 4 },
    { name = "nvim_lsp" },
    { name = "nvim_lua" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
  },
})
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

  lsp.default_keymaps({ buffer = bufnr })
end

lsp.on_attach(on_attach)

lsp.configure("rust_analyzer", {
  settings = {
    ['rust-analyzer'] = {
      check = {
        command = "clippy",
        extraArgs = { "--", "-A", "clippy::new_without_default", "-A", "clippy::needless_return" }
      }
    }
  }
})

lsp.configure("jsonls", {
  settings = {
    json = {
      schemas = require "schemastore".json.schemas(),
      validate = { enable = true }
    }
  }
})

lsp.configure("denols", {
  root_dir = nvim_lsp.util.root_pattern("deno.json", "deno.jsonc"),
})

lsp.nvim_workspace()

lsp.setup()

require("typescript").setup({
  disable_commands = false, -- prevent the plugin from creating Vim commands
  debug = false,            -- enable debug logging for commands
  go_to_source_definition = {
    fallback = true,        -- fall back to standard LSP definition on failure
  },
  server = {
    on_attach = on_attach,
    root_dir = nvim_lsp.util.root_pattern("package.json"),
    single_file_support = false,
    capabilities = require('cmp_nvim_lsp')
        .default_capabilities(vim.lsp.protocol.make_client_capabilities())
  }
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
      root_dir = function(fname)
        return nvim_lsp.util.find_git_ancestor(fname)
      end,
    },
  }
end

nvim_lsp.rstdls.setup({
  on_attach = on_attach,
  single_file_support = true,
  capabilities = require('cmp_nvim_lsp')
      .default_capabilities(vim.lsp.protocol.make_client_capabilities())
})

--[[ vim.lsp.set_log_level("debug"); ]]
