return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  config = function()
    require("snacks").setup({
      picker = {},
      input = {},
      notifier = {},
      image = {},
      styles = {
        input = {
          bo = {
            filetype = "snacks_input",
            buftype = "nofile",
          },
        }
      }
    })
  end,
}