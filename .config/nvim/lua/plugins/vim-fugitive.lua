return {
  "tpope/vim-fugitive",
  cmd = { "Git", "G", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse", "GRemove", "GRename", "Glgrep", "Gedit" },
  keys = {
    { "<leader>gs", ":G<CR>", desc = "Git status" },
    { "<leader>gg", ":G<CR>", desc = "Git status" },
  },
  config = function()
    local Gnarus_Fugitive = vim.api.nvim_create_augroup("Gnarus_Fugitive", {})

    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = Gnarus_Fugitive,
      pattern = "*",
      callback = function()
        if vim.bo.ft ~= "fugitive" then
          return
        end

        local bufnr = vim.api.nvim_get_current_buf()
        local opts = { buffer = bufnr, remap = false }

        vim.keymap.set("n", "<leader>t", ":Git push -u origin ", opts)
      end,
    })
  end,
}