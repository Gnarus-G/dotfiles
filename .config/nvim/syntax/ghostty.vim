" Use Neovim's built-in confini syntax highlighting for Ghostty config files.
if exists("b:current_syntax")
  finish
endif

runtime! syntax/confini.vim

let b:current_syntax = "ghostty"
