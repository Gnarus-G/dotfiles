local opts = { noremap = true, silent = true }

return {
  map = function(mode, before, after)
    vim.api.nvim_set_keymap(mode, before, after, opts)
  end,
  map_buf = function(bufnr, mode, before, after)
    vim.api.nvim_buf_set_keymap(bufnr, mode, before, after, opts)
  end
}
