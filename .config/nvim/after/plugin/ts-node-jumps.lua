local node_jumps = require "ts-node-jumps"

vim.keymap.set("n", "<up>", node_jumps.go_to_prev)
vim.keymap.set("n", "<down>", node_jumps.go_to_next)
