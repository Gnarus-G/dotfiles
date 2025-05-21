vim.cmd "let mapleader = \" \""

vim.keymap.set("n", "<leader>F", "<cmd>lua require('gnarus.formatting').async()<CR>")

vim.keymap.set("v", "J", ":m '>+1<cr>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<cr>gv=gv")

-- easier resizing
vim.keymap.set('n', '<C-up>', '5<C-w>+', { noremap = true, silent = true })
vim.keymap.set('n', '<C-down>', '5<C-w>-', { noremap = true, silent = true })
vim.keymap.set('n', '<C-left>', '5<C-w>>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-right>', '5<C-w><', { noremap = true, silent = true })
