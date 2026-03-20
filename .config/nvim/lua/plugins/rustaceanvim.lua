return {
  {
    'mrcjkb/rustaceanvim',
    version = '^8',
    lazy = false,
    init = function()
      local mason_registry = require('mason-registry')
      local codelldb = mason_registry.get_package('codelldb')
      local extension_path = codelldb:get_install_path() .. '/extension/'
      local codelldb_path = extension_path .. 'adapter/codelldb'
      local liblldb_path = extension_path .. 'lldb/lib/liblldb.so'

      ---@type rustaceanvim.Opts
      vim.g.rustaceanvim = {
        dap = {
          adapter = require('rustaceanvim.dap').get_codelldb_adapter(codelldb_path, liblldb_path),
        },
        server = {
          default_settings = {
            ['rust-analyzer'] = {
              checkOnSave = {
                command = "clippy",
                extraArgs = { "--", "-D", "warnings" },
              },
              rustfmt = {
                overrideCommand = { "rustfmt", "+nightly" },
              },
            },
          },
        },
      }
    end,
  },
}
