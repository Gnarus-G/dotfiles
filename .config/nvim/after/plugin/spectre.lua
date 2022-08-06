local ok, spectre = pcall(require, 'spectre')
if not ok then
  return
end

spectre.setup()

local map = require("gnarus.keymap").map;

map("n", "<leader>S", "<cmd>lua require('spectre').open()<CR>")
-- search current word
map("n", "<leader>sw", "<cmd>lua require('spectre').open_visual({select_word=true})<CR>")
map("v", "<leader>s", "<esc>:lua require('spectre').open_visual()<CR>")
--- search in current file
map("n", "<leader>sp", "viw:lua require('spectre').open_file_search()<cr>")
