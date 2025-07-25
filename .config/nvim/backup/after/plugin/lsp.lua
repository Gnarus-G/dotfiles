-- For lsp's that work on the same filetypes
---@param exclude string[]
---@param bufnr number
local function stop_clients(exclude, bufnr)
  local active_clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, active_client in ipairs(active_clients) do
    if vim.tbl_contains(exclude, active_client.name) then
      vim.lsp.stop_client(active_client.id)
    end
  end
end

-- note: diagnostics are not exclusive to lsp servers
-- so these can be global keybindings
vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>')
vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')
vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')

--
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, remap = false }

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  vim.keymap.set('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  vim.keymap.set('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  vim.keymap.set('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  vim.keymap.set('n', '<leader>wl',
    '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  vim.keymap.set('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.keymap.set({ 'n', 'v' }, '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)

  vim.keymap.set('n', '<leader>lr', vim.lsp.codelens.run, { buffer = bufnr, remap = false })
end

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    on_attach(nil, event.buf)
  end
})

local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

require('mason').setup({ PATH = "append" })
require('mason-lspconfig').setup({
  ensure_installed = { 'rust_analyzer', 'ts_ls', 'dockerls', "cssls", "clangd", "lua_ls", "jsonls" },
  automatic_enable = true
})

vim.lsp.config("ocamllsp", {
  capabilities = lsp_capabilities,
})

vim.lsp.config("lua_ls", {
  capabilities = lsp_capabilities,
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      diagnostics = {
        globals = { 'vim' },
      },
      workspace = {
        library = {
          vim.env.VIMRUNTIME,
          vim.fn.expand "~/.local/share/nvim/site/pack/packer/start/"
        }
      }
    }
  }
})

vim.lsp.config("rust_analyzer", {
  capabilities = lsp_capabilities,
  settings = {
    ['rust-analyzer'] = {
      checkOnSave = true,
      rustfmt = {
        overrideCommand = { "rustfmt", "+nightly", "--edition", "2021" },
      }
    }
  }
})

vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = require "schemastore".json.schemas(),
      validate = { enable = true }
    }
  }
})

vim.lsp.config("ts_ls", {
  root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json' },
})
vim.lsp.enable("ts_ls", false)

require("typescript-tools").setup {
  on_attach = function(client, bufnr)
    -- Disable document formatting capabilities, we use prettierd with none-ls
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false

    vim.api.nvim_create_autocmd("LspAttach", {
      desc = 'Stop denols in favor of typescript-tools',
      callback = function(_)
        stop_clients({ "denols" }, bufnr)
      end
    })
  end,
  single_file_support = false,
  root_dir = require('lspconfig.util').root_pattern('package.json', 'tsconfig.json', 'jsconfig.json'),
  settings = {
    code_lens = "references_only",
    -- by default code lenses are displayed on all referencable values and for some of you it can
    -- be too much this option reduce count of them by removing member references from lenses
    disable_member_code_lens = true,
    tsserver_file_preferences = {
      includeInlayParameterNameHints = "all",
    },
  }
}

vim.lsp.config("denols", {
  single_file_support = true,
  root_markers = { 'deno.json', 'deno.jsonc', }
})

vim.diagnostic.config({
  virtual_text = true,
})

vim.lsp.config("rstdls", {
  capabilities = lsp_capabilities
})

vim.lsp.config("cnls", {
  cmd = { "cnls" },
  filetypes = { "javascriptreact", "typescriptreact" },
  root_markers = { "package.json" },
  capabilities = lsp_capabilities,
  settings = {
    cnls = {
      scopes = { "att:className,class,classes,*ClassName", "fn:createElement,cva", "prop:className" }
    }
  }
})

vim.lsp.config("todols", {
  cmd = { "todo", "lsp" },
  filetypes = { "todolang" },
  single_file_support = true,
  capabilities = lsp_capabilities
})

vim.lsp.enable { "cnls", "todols" }

--[[ vim.lsp.set_log_level("debug"); ]]
--[[ require('vim.lsp.log').set_format_func(vim.inspect) ]]
