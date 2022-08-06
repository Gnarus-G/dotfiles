require "user.options"
require "user.plugins"
require "user.remaps"

vim.cmd [[
  augroup highlight_yank
      autocmd!
      autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({timeout = 40})
  augroup END
]]
