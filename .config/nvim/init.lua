require "gnarus.options"
require "gnarus.plugins"
require "gnarus.remaps"

vim.cmd [[
  augroup highlight_yank
      autocmd!
      autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({timeout = 40})
  augroup END
]]
