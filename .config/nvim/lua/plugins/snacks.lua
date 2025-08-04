return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    dashboard = {
      enabled = true,
      width = 60,
      row = nil,
      col = nil,
      pane_gap = 4,
      autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
      preset = {
        header = { [[

     ██████╗ ███╗   ██╗ █████╗ ██████╗ ██╗   ██╗███████╗
    ██╔════╝ ████╗  ██║██╔══██╗██╔══██╗██║   ██║██╔════╝
    ██║  ███╗██╔██╗ ██║███████║██████╔╝██║   ██║███████╗
    ██║   ██║██║╚██╗██║██╔══██║██╔══██╗██║   ██║╚════██║
    ╚██████╔╝██║ ╚████║██║  ██║██║  ██║╚██████╔╝███████║
     ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝]],
        },
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = "<leader>ff" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          --[[ { icon = " ", key = "g", desc = "Live Grep", action = "<leader>fg" }, ]]
          --[[ { icon = " ", key = "r", desc = "Recent Files", action = "<leader>fo" }, ]]
          { icon = " ", key = "p", desc = "Projects", action = "<leader>fp" },
          { icon = " ", key = "c", desc = "Config", action = ":e ~/.config/nvim/init.lua" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
      formats = {
        key = function(item) return { { "[", hl = "Special" }, { item.key, hl = "Keyword" }, { "]", hl = "Special" } } end,
        icon = function(item) return item.icon and { item.icon, hl = "Type" } or nil end,
        desc = function(item) return item.desc and { item.desc, hl = "Comment" } or nil end,
        header = { "%s", align = "center" }
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = { 2, 2 } },
        --[[ { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 2 }, ]]
        function()
          local in_git = Snacks.git.get_root() ~= nil
          local cmds = {
            {
              icon = " ",
              title = "Git Status",
              cmd = "git --no-pager diff --stat -B -M -C",
              height = 5,
            },
            {
              title = "Open Issues",
              cmd = "gh issue list -L 5",
              key = "i",
              action = function()
                vim.fn.jobstart("gh issue list --web", { detach = true })
              end,
              icon = " ",
              height = 3,
            },
            {
              icon = " ",
              title = "Open PRs",
              cmd = "gh pr list -L 3",
              key = "P",
              action = function()
                vim.fn.jobstart("gh pr list --web", { detach = true })
              end,
              height = 2,
            },
          }
          return vim.tbl_map(function(cmd)
            return vim.tbl_extend("force", {
              section = "terminal",
              enabled = in_git,
              padding = 1,
              ttl = 5 * 60,
              indent = 3,
            }, cmd)
          end, cmds)
        end,
        { section = "startup" },
      },
    },
    image = { enabled = true },
    bigfile = { enabled = true },
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
    },
  },
  keys = {
    { "<leader>d",  function() Snacks.dashboard.open() end,                                        desc = "Dashboard" },
    { "<leader>fp", function() Snacks.picker.projects() end,                                       desc = "Projects" },
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
