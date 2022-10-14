require "gnarus.options"
require "gnarus.plugins"
require "gnarus.remaps"

-- Format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true }),
  callback = require "gnarus.formatting".sync
})

-- highlight_yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    require 'vim.highlight'.on_yank({ timeout = 40 })
  end
})
