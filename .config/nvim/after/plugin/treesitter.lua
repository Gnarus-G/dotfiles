require 'nvim-treesitter.configs'.setup {
  ensure_installed = { "lua" },
  autotag = {
    enable = true,
    filetypes = { "html", "xml", "tsx" }
  },
  highlight = { enable = true },
  incremental_selection = { enable = true },
  textobjects = { enable = true }
}
