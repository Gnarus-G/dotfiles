local map = require("gnarus.keymap").map;

vim.cmd "let mapleader = \" \""

map("i", "jk", "<Esc>")
map("n", "<leader>e", "<cmd>Lex 25<cr>")

map("n", "<leader>F", "<cmd>lua vim.lsp.buf.formatting()<CR>")

map("n", "<leader>n","<cmd>/function<cr>")
map("n", "<leader>N","<cmd>?function<cr>")
