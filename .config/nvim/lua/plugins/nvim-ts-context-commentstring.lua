return {
  "JoosepAlviste/nvim-ts-context-commentstring",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require('ts_context_commentstring').setup({
      enable_autocmd = false,
    })
  end,
}