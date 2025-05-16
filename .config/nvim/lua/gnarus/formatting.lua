local excluded_clients = {
  "ts_ls",
  "jsonls",
  "typescript-tools",
  "astro",
}

-- Disable native formatting for specific LSP servers
---@param client vim.lsp.Client
---@return boolean
local function format_filter(client)
  return not vim.tbl_contains(excluded_clients, client.name);
end

-- Format synchronously on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true }),
  callback = function()
    vim.lsp.buf.format({
      filter = format_filter
    })
  end
})

return {
  async = function()
    vim.lsp.buf.format({
      filter = format_filter,
      async = true
    })
  end
}
