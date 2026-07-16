return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  build = "make",
  opts = {
    provider = "codex",
    mode = "agentic",
    acp_providers = {
      codex = {
        command = "codex-acp",
        args = {},
        env = {
          NODE_NO_WARNINGS = "1",
          HOME = os.getenv("HOME"),
          PATH = os.getenv("PATH"),
          CODEX_PATH = vim.fn.exepath("codex"),
        },
      },
      ["claude-code"] = {
        command = "claude-agent-acp",
        args = {},
        env = {
          NODE_NO_WARNINGS = "1",
          HOME = os.getenv("HOME"),
          PATH = os.getenv("PATH"),
          ACP_PERMISSION_MODE = "default",
        },
      },
    },
    input = {
      provider = "snacks",
    },
    selector = {
      provider = "snacks",
    },
  },
  keys = {
    { "<leader>ap", "<cmd>AvanteSwitchProvider<cr>", desc = "Avante switch provider" },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "folke/snacks.nvim",
    "nvim-tree/nvim-web-devicons",
    "HakonHarnes/img-clip.nvim",
    "MeanderingProgrammer/render-markdown.nvim",
  },
}
