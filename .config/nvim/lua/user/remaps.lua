local map = require("user.keymap").map;

vim.cmd "let mapleader = \" \""

map("i", "jk", "<Esc>")
map("n", "<leader>e", "<cmd>Lex 25<cr>")

map("n", "<leader>F", "<cmd>lua vim.lsp.buf.formatting()<CR>")
