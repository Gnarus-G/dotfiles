local ok, nvim_tree = pcall(require, ("nvim-tree"))
if not ok then
  return
end

nvim_tree.setup({
  sort_by = "case_sensitive",
  view = {
    adaptive_size = true,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = false,
  },
})

vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeFindFileToggle<CR>")
