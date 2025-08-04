return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    image = { enabled = true },
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true },
    picker = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    styles = {
      input = {
        bo = {
          filetype = "snacks_input",
          buftype = "nofile",
        },
      }
    }
  },
  keys = {
    { "<C-p>",      function() Snacks.picker.files() end,                                          desc = "Find files" },
    { "<leader>ff", function() Snacks.picker.files({ hidden = true }) end,                         desc = "Find files (hidden)" },
    { "<leader>fg", function() Snacks.picker.grep() end,                                           desc = "Live grep" },
    { "<leader>hg", function() Snacks.picker.grep({ hidden = true, glob = { "!**/.git/*" } }) end, desc = "Live grep (hidden files)" },
    { "<leader>fo", function() Snacks.picker.recent() end,                                         desc = "Old files" },
    { "<leader>fb", function() Snacks.picker.buffers() end,                                        desc = "Buffers" },
    { "<leader>fh", function() Snacks.picker.help() end,                                           desc = "Help tags" },
    { "<leader>fr", function() Snacks.picker.lsp_references() end,                                 desc = "LSP references" },
    { "<leader>gc", function() Snacks.picker.git_log_file() end,                                   desc = "Git buffer commits" },
    { "<leader>gC", function() Snacks.picker.git_log() end,                                        desc = "Git commits" },
  }
}
