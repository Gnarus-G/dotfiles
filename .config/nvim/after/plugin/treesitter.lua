require 'nvim-treesitter.configs'.setup {
  ensure_installed = { "lua", "rust", "javascript", "typescript", "tsx" },
  sync_install = false,
  auto_install = true,
  autotag = {
    enable = true,
    filetypes = { "html", "xml", "tsx" }
  },
  highlight = { enable = true },
  incremental_selection = { enable = true },
  textobjects = { enable = true }
}
