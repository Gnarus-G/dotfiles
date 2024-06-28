local codelens_augroup = vim.api.nvim_create_augroup("todols:codeLenses", { clear = true })

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'Sets up todols codelens autocommands',
  pattern = { "*.td", "*.todo" },
  group = codelens_augroup,
  callback = function(event)
    vim.api.nvim_create_autocmd({ 'CursorHold', 'BufEnter', 'InsertLeave' }, {
      group = codelens_augroup,
      buffer = event.buf,
      callback = function()
        vim.lsp.codelens.refresh({ bufnr = event.buf })
      end
    })

    vim.api.nvim_create_autocmd('LspDetach', {
      group = codelens_augroup,
      buffer = event.buf,
      callback = function(e)
        vim.lsp.codelens.clear(e.data.client_id, e.buf)
      end
    })
  end
})
