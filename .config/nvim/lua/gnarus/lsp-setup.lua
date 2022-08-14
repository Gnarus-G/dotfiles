local map_buf = require("gnarus.keymap").map_buf;

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Disable native language formatting for certain lsp servers
  -- assuming that null-ls will handle it later
  for _, name in pairs({ "tsserver", "jsonls", "astro" }) do
    if client.name == name then
      client.resolved_capabilities.document_formatting = false
    end
  end

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  map_buf(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
  map_buf(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  map_buf(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  map_buf(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
  map_buf(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
  map_buf(bufnr, 'n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>')
  map_buf(bufnr, 'n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>')
  map_buf(bufnr, 'n', '<leader>wl',
    '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>')
  map_buf(bufnr, 'n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
  map_buf(bufnr, 'n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<CR>')
  map_buf(bufnr, 'n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>')
  map_buf(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
  map_buf(bufnr, 'n', '<leader>F', '<cmd>lua vim.lsp.buf.formatting()<CR>')
end

-- Setup lspconfig.
local capabilities = require('cmp_nvim_lsp')
    .update_capabilities(vim.lsp.protocol.make_client_capabilities())

-- Lsp Config
local ok, lspconfig = pcall(require, "lspconfig")
if not ok then
  return
end

return function(server, more_opts)
  local opts = vim.tbl_deep_extend("force", {
    on_attach = on_attach,
    capabilities = capabilities
  }, more_opts)

  lspconfig[server].setup(opts)
end
