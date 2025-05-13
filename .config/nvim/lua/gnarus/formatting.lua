local function format_filter(client)
  -- Disable native language formatting for certain lsp servers
  -- assuming that null-ls wll handle it later
  for _, name in pairs({ "ts_ls", "jsonls", "astro" }) do
    if client.name == name then
      return false
    end
  end
  return true;
end

return {
  sync = function()
    vim.lsp.buf.format({
      filter = format_filter
    })
  end,
  async = function()
    vim.lsp.buf.format({
      filter = format_filter,
      async = true
    })
  end
}
