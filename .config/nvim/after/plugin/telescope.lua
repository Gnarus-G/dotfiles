local ok, telescope = pcall(require, 'telescope');
if not ok then
  return
end

telescope.setup {
  defaults = {
    -- Default configuration for telescope goes here:
    -- config_key = value,
    mappings = {
      i = {
        -- map actions.which_key to <S-/> (default: <C-/>)
        -- actions.which_key shows the mappings for your picker,
        -- e.g. git_{create, delete, ...}_branch for the git_branches picker
        ["<S-/>"] = "which_key"
      }
    }
  },
  pickers = {
    -- Default configuration for builtin pickers goes here:
    -- picker_name = {
    --   picker_config_key = value,
    --   ...
    -- }
    -- Now the picker_config_key will be applied every time you call this
    -- builtin picker
  },
  extensions = {
    -- Your extension configuration goes here:
    -- extension_name = {
    --   extension_config_key = value,
    -- }
    -- please take a look at the readme of the extension you want to configure
  }
}

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<c-p>", "<cmd>Telescope find_files find_command=rg,--ignore,--files prompt_prefix=🔍<cr>")
vim.keymap.set("n", "<leader>ff",
  "<cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files prompt_prefix=🔍<cr>")
vim.keymap.set("n", "<leader>fg", builtin.live_grep)
vim.keymap.set("n", "<leader>fo", builtin.oldfiles)
vim.keymap.set("n", "<leader>fb", builtin.buffers)
vim.keymap.set("n", "<leader>fh", builtin.help_tags)
-- Lsp vim.keymap.setpings
vim.keymap.set("n", "<leader>fr", builtin.lsp_references)
-- Git vim.keymap.setpings
vim.keymap.set("n", "<leader>gc", builtin.git_bcommits)
vim.keymap.set("n", "<leader>gC", builtin.git_commits)
