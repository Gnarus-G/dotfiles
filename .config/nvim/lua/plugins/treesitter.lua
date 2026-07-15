return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local parsers = {
        "bash",
        "html",
        "javascript",
        "lua",
        "markdown",
        "markdown_inline",
        "rust",
        "todolang",
        "tsx",
        "typescript",
        "yaml",
      }

      require("nvim-treesitter").install(parsers)

      local filetypes = {}
      for _, parser in ipairs(parsers) do
        vim.list_extend(filetypes, vim.treesitter.language.get_filetypes(parser))
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true }),
        pattern = vim.list.unique(filetypes),
        callback = function(event)
          pcall(vim.treesitter.start, event.buf)
        end,
      })

      vim.treesitter.language.register("markdown", "mdx")
    end,
  },
}
