local ok, null_ls = pcall(require, "null-ls");

if not ok then
  return
end

null_ls.setup({
  sources = {
    null_ls.builtins.formatting.prettierd.with({
      extra_filetypes = { "astro" },
    }),
    null_ls.builtins.diagnostics.eslint_d.with({
      condition = function(utils)
        return utils.root_has_file({ "package.json" })
      end,
    }),
    null_ls.builtins.code_actions.eslint_d.with({
      condition = function(utils)
        return utils.root_has_file({ "package.json" })
      end,
    }),
    null_ls.builtins.code_actions.gitsigns,
    require("typescript.extensions.null-ls.code-actions"),
  },
})
