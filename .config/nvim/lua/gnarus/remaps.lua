vim.cmd "let mapleader = \" \""

vim.keymap.set("n", "<leader>e", "<cmd>Lex 25<cr>")

vim.keymap.set("n", "<leader>F", "<cmd>lua require('gnarus.formatting').async()<CR>")

vim.keymap.set("v", "J", ":m '>+1<cr>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<cr>gv=gv")
