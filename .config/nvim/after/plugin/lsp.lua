local map = require("gnarus.keymap").map

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
map('n', '<leader>D', '<cmd>lua vim.diagnostic.open_float()<CR>')
map('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
map('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>')
map('n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>')

-- Lsp Installer
local ok, lsp_installer = pcall(require, "nvim-lsp-installer")
if not ok then
  return
end

lsp_installer.setup({
  automatic_installation = true, -- automatically detect which servers to install (based on which servers are set up via lspconfig)
  ui = {
    icons = {
      server_installed = "✓",
      server_pending = "➜",
      server_uninstalled = "✗"
    }
  }
})

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { 'rust_analyzer', 'tsserver', 'gopls', 'vimls', 'tailwindcss', 'prismals', 'dockerls', 'svelte', "cssls",
  "clangd" }

local lsp_setup = require "gnarus.lsp-setup";

for _, lsp in pairs(servers) do
  lsp_setup(lsp, {})
end

lsp_setup("sumneko_lua", {
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { 'vim' },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
    },
  }
})

lsp_setup("jsonls", {
  settings = {
    json = {
      schemas = require "schemastore".json.schemas(),
      validate = { enable = true }
    }
  }
})

lsp_setup("astro", {})
