local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
parser_config.todolang = {
  install_info = {
    url = "~/d/tree-sitter-todolang",       -- local path or git repo
    files = { "src/parser.c" },             -- note that some parsers also require src/scanner.c or src/scanner.cc
    -- optional entries:
    branch = "main",                        -- default branch in case of git repo if different from master
    generate_requires_npm = false,          -- if stand-alone parser without npm dependencies
    requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
  },
}

vim.filetype.add({
  extension = {
    todo = "todolang",
    td = "todolang"
  }
})
