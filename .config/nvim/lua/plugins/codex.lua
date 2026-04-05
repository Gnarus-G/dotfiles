return {
  "pittcat/codex.nvim",
  cmd = { "CodexOpen", "CodexToggle", "CodexSendPath", "CodexSendSelection" },
  keys = {
    { "<leader>cc", function() require("codex").open() end, desc = "Codex: open" },
    { "<leader>ct", function() require("codex").toggle() end, desc = "Codex: toggle" },
    { "<leader>cp", ":CodexSendPath<CR>", desc = "Codex: send file path" },
    { "<leader>cs", ":'<,'>CodexSendSelection<CR>", mode = "v", desc = "Codex: send selection" },
  },
  opts = {
    terminal = {
      provider = "auto",
      direction = "vertical",
      position = "right",
      size = 0.35,
      reuse = true,
    },
    terminal_bridge = {
      path_format = "rel",
      path_prefix = "@",
      auto_attach = true,
      selection_mode = "reference",
    },
  },
}
