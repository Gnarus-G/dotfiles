return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    "neovim/nvim-lspconfig",
  },
  config = function()
    local codelens_augroup = vim.api.nvim_create_augroup("todols:codeLenses", { clear = true })

    vim.api.nvim_create_autocmd('LspAttach', {
      desc = 'Sets up todols codelens autocommands',
      pattern = { "*.td", "*.todo" },
      group = codelens_augroup,
      callback = function(event)
        vim.api.nvim_create_autocmd({ 'CursorHold', 'BufEnter', 'InsertLeave' }, {
          group = codelens_augroup,
          buffer = event.buf,
          callback = function()
            vim.lsp.codelens.refresh({ bufnr = event.buf })
          end
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = codelens_augroup,
          buffer = event.buf,
          callback = function(e)
            vim.lsp.codelens.clear(e.data.client_id, e.buf)
          end
        })
      end
    })

    -- Syntax highlighting for todolang using tree-sitter
    local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
    parser_config.todolang = {
      install_info = {
        url = "https://github.com/Gnarus-G/tree-sitter-todolang", -- local path or git repo
        files = { "src/parser.c" },                               -- note that some parsers also require src/scanner.c or src/scanner.cc
        -- optional entries:
        branch = "main",                                          -- default branch in case of git repo if different from master
        generate_requires_npm = false,                            -- if stand-alone parser without npm dependencies
        requires_generate_from_grammar = false,                   -- if folder contains pre-generated src/parser.c
      },
    }


  end,
}