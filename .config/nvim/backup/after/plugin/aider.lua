local nvim_aider = require("nvim_aider")

---@class nvim_aider.Config
local opts = {
  -- Command that executes Aider
  aider_cmd = "aider",
  -- Command line arguments passed to aider
  args = {
    "--model gemini",
    "--no-auto-commits",
    "--pretty",
    "--stream",
    "--watch",
    "--yes-always"
  },
  -- Automatically reload buffers changed by Aider (requires vim.o.autoread = true)
  auto_reload = false,
  -- snacks.picker.layout.Config configuration
  picker_cfg = {
    preset = "vscode",
    layout = {}
  },
  -- Other snacks.terminal.Opts options
  config = {
    os = { editPreset = "nvim-remote" },
    gui = { nerdFontsVersion = "3" },
  },
  win = {
    wo = { winbar = "Aider" },
    style = "nvim_aider",
    position = "right",
    relative = "editor",
  },
}

nvim_aider.setup(opts)

local group = vim.api.nvim_create_augroup("AiderKeymaps", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "NvimTree",
  callback = function()
    vim.keymap.set("n", "a", ":AiderTreeAddFile<cr>",
      { desc = "Add File to Aider", buffer = true })
    vim.keymap.set("n", "d", ":AiderTreeDropFile<cr>",
      { desc = "Drop File from Aider", buffer = true })
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    vim.keymap.set("n", "<leader>a/", ":Aider toggle<cr>", { desc = "Toggle Aider" })
    vim.keymap.set({ "n", "v" }, "<leader>as", ":Aider send<cr>", { desc = "Send to Aider" })
    vim.keymap.set("n", "<leader>ac", ":Aider command<cr>", { desc = "Aider Commands" })
    vim.keymap.set("n", "<leader>ab", ":Aider buffer<cr>", { desc = "Send Buffer" })
    vim.keymap.set("n", "<leader>a+", ":Aider add<cr>", { desc = "Add File" })
    vim.keymap.set("n", "<leader>a-", ":Aider drop<cr>", { desc = "Drop File" })
    vim.keymap.set("n", "<leader>ar", ":Aider add readonly<cr>", { desc = "Add Read-Only" })
    vim.keymap.set("n", "<leader>aR", ":Aider reset<cr>", { desc = "Reset Session" })
  end,
})

---@class nvim_aider.api
---@field health_check fun()
---@field toggle_terminal fun(opts?: table)
---@field send_to_terminal fun(text?: string, opts?: table)
---@field send_command fun(command: string, input?: string, opts?: table)
---@field send_buffer_with_prompt fun(opts?: table)
---@field send_diagnostics_with_prompt fun(opts?: table)
---@field add_file fun(filepath: string, opts?: table)
---@field add_current_file fun(opts?: table)
---@field drop_file fun(filepath: string, opts?: table)
---@field drop_current_file fun(opts?: table)
---@field add_read_only_file fun(opts?: table)
---@field reset_session fun(opts?: table)
---@field open_command_picker fun(opts?: table, callback?: fun(picker_instance: any, item: {category: string, text: string}))
local nvim_aider_api = nvim_aider.api
