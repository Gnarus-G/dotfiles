return {
  "nickjvandyke/opencode.nvim",
  version = "*",
  dependencies = {
    {
      "folke/snacks.nvim",
      optional = true,
      ---@module 'snacks'
      opts = {
        input = {},
        terminal = {},
        picker = {
          actions = {
            opencode_send = function(...) return require("opencode").snacks_picker_send(...) end,
          },
          win = {
            input = {
              keys = {
                ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
              },
            },
          },
        },
      },
    },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      events = {
        enabled = true,
        reload = true,
        permissions = {
          enabled = true,
          edits = { enabled = true },
        },
      },
      lsp = {
        enabled = false,
      },
      prompts = {
        diagnostics = { prompt = "Explain @diagnostics", submit = true },
        diff = { prompt = "Review the following git diff for correctness and readability: @diff", submit = true },
        explain = { prompt = "Explain @this and its context", submit = true },
        review = { prompt = "Review @this for correctness and readability", submit = true },
        document = { prompt = "Add comments documenting @this", submit = true },
        fix = { prompt = "Fix @diagnostics", submit = true },
        implement = { prompt = "Implement @this", submit = true },
        optimize = { prompt = "Optimize @this for performance and readability", submit = true },
        test = { prompt = "Add tests for @this", submit = true },
        debug = { prompt = "Add debug logging to @this", ask = true, submit = false },
      },
    }

    vim.o.autoread = true

    vim.keymap.set({ "n", "x" }, "<C-a>", function() require("opencode").ask("@this: ", { submit = true }) end,
      { desc = "Ask opencode…" })
    vim.keymap.set({ "n", "x" }, "<C-x>", function() require("opencode").select() end,
      { desc = "Execute opencode action…" })
    vim.keymap.set({ "n", "t" }, "<C-.>", function() require("opencode").toggle() end, { desc = "Toggle opencode" })

    vim.keymap.set({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end,
      { desc = "Add range to opencode", expr = true })
    vim.keymap.set("n", "goo", function() return require("opencode").operator("@this ") .. "_" end,
      { desc = "Add line to opencode", expr = true })

    vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end,
      { desc = "Scroll opencode up" })
    vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end,
      { desc = "Scroll opencode down" })

    vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
    vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
  end,
}

