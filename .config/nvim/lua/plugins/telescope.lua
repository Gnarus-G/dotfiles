return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = "Telescope",
  keys = {
    { "<C-p>", function()
      require("telescope.builtin").find_files({ find_command = { "rg", "--ignore", "--files" }, prompt_prefix = "🔍" })
    end, desc = "Find files" },
    { "<leader>ff", function()
      require("telescope.builtin").find_files({ find_command = { "rg", "--ignore", "--hidden", "--files" }, prompt_prefix = "🔍" })
    end, desc = "Find files (hidden)" },
    { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Live grep" },
    { "<leader>fo", function() require("telescope.builtin").oldfiles() end, desc = "Old files" },
    { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
    { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Help tags" },
    { "<leader>fr", function() require("telescope.builtin").lsp_references() end, desc = "LSP references" },
    { "<leader>gc", function() require("telescope.builtin").git_bcommits() end, desc = "Git buffer commits" },
    { "<leader>gC", function() require("telescope.builtin").git_commits() end, desc = "Git commits" },
    { "<leader>rr", function()
      require('telescope').extensions.refactoring.refactors()
    end, mode = { "n", "x" }, desc = "Refactoring" },
  },
  config = function()
    require("telescope").setup({
      defaults = {
        mappings = {
          i = {
            ["<S-/>"] = "which_key"
          }
        }
      },
      pickers = {},
      extensions = {}
    })
    
    require("telescope").load_extension("refactoring")
  end,
}