local ok, null_ls = pcall(require, "null-ls");

if not ok then
  return
end

null_ls.setup({
  --- @param bufnr number
  --- @return boolean
  should_attach = function(bufnr)
    local buf_name = vim.api.nvim_buf_get_name(bufnr);
    local excluded = buf_name:match("^fugitive://") or buf_name:match("NvimTree");
    return not excluded
  end,
  sources = {
    null_ls.builtins.formatting.prettierd.with({
      extra_filetypes = { "astro" },
    }),
    null_ls.builtins.diagnostics.eslint_d.with({
      condition = function(utils)
        return utils.root_has_file({ "package.json" })
            and utils.root_has_file_matches(".eslintrc.*")
      end,
    }),
    null_ls.builtins.code_actions.eslint_d.with({
      condition = function(utils)
        return utils.root_has_file({ "package.json" })
            and utils.root_has_file_matches(".eslintrc.*")
      end,
    }),
    null_ls.builtins.code_actions.gitsigns,
  },
})
