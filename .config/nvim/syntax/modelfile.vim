if exists("b:current_syntax")
  finish
endif

syn keyword inst_keyword FROM TEMPLATE PARAMETER MESSAGE SYSTEM ADAPTER LICENSE
syn region string oneline start=/"/ end=/"/
syn region multiline_string start=/"""/ end=/"""/

syn match comment /#.*$/
hi def link comment Comment

hi def link string String
hi def link multiline_string String
hi def link inst_keyword Keyword

let b:current_syntax = "modelfile"
