return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>a", function() require("harpoon"):list():add() end,     desc = "Harpoon: Add file" },
    {
      "<C-e>",
      function()
        local harpoon = require("harpoon")
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = "Harpoon: Toggle quick menu"
    },
    { "<S-h>",     function() require("harpoon"):list():select(1) end, desc = "Harpoon: Select file 1" },
    { "<S-l>",     function() require("harpoon"):list():select(2) end, desc = "Harpoon: Select file 2" },
    { "<S-m>",     function() require("harpoon"):list():select(3) end, desc = "Harpoon: Select file 3" },
  },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()
  end,
}
