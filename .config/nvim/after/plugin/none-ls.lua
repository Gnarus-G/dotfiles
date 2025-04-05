local ok, none_ls = pcall(require, "none-ls");

if not ok then
  return
end

none_ls.setup({
  --- @param bufnr number
  --- @return boolean
  should_attach = function(bufnr)
    local buf_name = vim.api.nvim_buf_get_name(bufnr);
    local excluded = buf_name:match("^fugitive://") or buf_name:match("NvimTree");
    return not excluded
  end,
  sources = {
    none_ls.builtins.formatting.prettierd.with({
      extra_filetypes = { "astro" },
    }),
    none_ls.builtins.diagnostics.eslint_d.with({
      condition = function(utils)
        return utils.root_has_file({ "package.json" })
            and utils.root_has_file_matches(".eslintrc.*")
      end,
    }),
    none_ls.builtins.code_actions.eslint_d.with({
      condition = function(utils)
        return utils.root_has_file({ "package.json" })
            and utils.root_has_file_matches(".eslintrc.*")
      end,
    }),
    none_ls.builtins.code_actions.gitsigns,
  },
})
