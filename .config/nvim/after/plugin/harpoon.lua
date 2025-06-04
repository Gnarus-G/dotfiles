local harpoon = require("harpoon")

-- REQUIRED: Setup harpoon.
-- You can add configuration options within the curly braces if needed.
-- For example: harpoon:setup({ settings = { save_on_toggle = true } })
-- See the harpoon2 README for available options.
harpoon:setup()

-- Keymaps
vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon: Add file" })
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
  { desc = "Harpoon: Toggle quick menu" })

vim.keymap.set("n", "<S-h>", function() harpoon:list():select(1) end, { desc = "Harpoon: Select file 1" })
vim.keymap.set("n", "<S-l>", function() harpoon:list():select(2) end, { desc = "Harpoon: Select file 2" })
vim.keymap.set("n", "<S-m>", function() harpoon:list():select(3) end, { desc = "Harpoon: Select file 3" })

-- Optional: Add keymaps for navigating next/prev in the harpoon list
-- vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end, { desc = "Harpoon: Previous file" })
-- vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end, { desc = "Harpoon: Next file" })
