local map = require("user.keymap").map

map("n", "<c-p>", "<cmd>Telescope find_files<cr>")
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
map("n", "<leader>fh ", "<cmd>Telescope help_tags<cr>")
