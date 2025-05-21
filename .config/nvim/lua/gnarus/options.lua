local o = vim.opt

o.completeopt = { "menuone", "noinsert", "noselect" }
o.expandtab = true
o.tabstop = 2
o.softtabstop = 2
o.shiftwidth = 2
o.number = true
o.relativenumber = true
o.hlsearch = false
o.hidden = true
o.errorbells = false
o.wrap = false
o.swapfile = false
o.backup = false
o.undodir = vim.fn.expand("~") .. '/.vim/undodir'
o.undofile = true
o.incsearch = true
o.scrolloff = 8
o.signcolumn = "yes"
o.colorcolumn = "80"
o.mouse = "a"

vim.cmd "filetype plugin indent on"
