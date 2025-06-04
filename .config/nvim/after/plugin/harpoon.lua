local harpoon = require("harpoon")

harpoon:setup()

-- Global Keymaps (user-defined, outside of Harpoon UI)
vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon: Add file" })
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
  { desc = "Harpoon: Toggle quick menu" })

vim.keymap.set("n", "<S-h>", function() harpoon:list():select(1) end, { desc = "Harpoon: Select file 1" })
vim.keymap.set("n", "<S-l>", function() harpoon:list():select(2) end, { desc = "Harpoon: Select file 2" })
vim.keymap.set("n", "<S-m>", function() harpoon:list():select(3) end, { desc = "Harpoon: Select file 3" })

require("minuet_ctx.harpoon")
