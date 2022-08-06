local map = require("gnarus.keymap").map;

vim.opt.termguicolors = true
require("bufferline").setup {
  options = {
    offsets = { { filetype = "NvimTree", text = "", padding = 1 } },
  }
}

map("n", "H", "<cmd>BufferLineCyclePrev<CR>")
map("n", "L", "<cmd>BufferLineCycleNext<CR>")
map("n", "<leader>C", "<cmd>bdelete<CR>")
