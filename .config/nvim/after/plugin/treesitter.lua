---@diagnostic disable-next-line: missing-fields
require 'nvim-treesitter.configs'.setup {
  ensure_installed = { "html", "lua", "rust", "javascript", "typescript", "tsx" },
  sync_install = false,
  auto_install = true,
  highlight = { enable = true },
  incremental_selection = { enable = true },
  textobjects = { enable = true },
  ignore_install = {}
}

vim.treesitter.language.register("markdown", "mdx")
