require("tailwind-tools").setup(
  {
    document_color = {
      enabled = true, -- can be toggled by commands
      kind = "inline", -- "inline" | "foreground" | "background"
      inline_symbol = "󰝤 ", -- only used in inline mode
      debounce = 200, -- in milliseconds, only applied in insert mode
    },
    conceal = {
      symbol = "󱏿", -- only a single character is allowed
      highlight = { -- extmark highlight options, see :h 'highlight'
        fg = "#38BDF8",
      },
    },
  })

-- Format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("FormatOnSave", { clear = false }),
  callback = function()
    vim.cmd ":TailwindSort"
  end
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("TailwindFold", { clear = true }),
  callback = function()
    vim.cmd ":TailwindConcealEnable"
  end
})
