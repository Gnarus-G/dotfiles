local map = require("gnarus.keymap").map;

vim.cmd "let mapleader = \" \""

map("i", "jk", "<Esc>")
map("n", "<leader>e", "<cmd>Lex 25<cr>")

map("n", "<leader>F", "<cmd>lua vim.lsp.buf.formatting()<CR>")

map("v", "J", ":m '>+1<cr>gv=gv")
map("v", "K", ":m '<-2<cr>gv=gv")
