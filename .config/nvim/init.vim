inoremap jk <Esc>

" Control + S to save the buffer
noremap <C-S>          :w<CR>
vnoremap <C-S>         <C-C>:w<CR>
inoremap <C-S>         <C-O>:w<CR>

set completeopt=menuone,noinsert,noselect
set tabstop=4 softtabstop=4
set relativenumber
set nohlsearch
set hidden
set noerrorbells
set nowrap
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set incsearch
set scrolloff=8
set signcolumn=yes
set colorcolumn=80
filetype plugin indent on

call plug#begin('~/.vim/plugged')
Plug 'tomasiser/vim-code-dark'
Plug 'pangloss/vim-javascript'
Plug 'itchyny/lightline.vim'
Plug 'itchyny/vim-gitbranch'

Plug 'kassio/neoterm'
Plug 'tpope/vim-commentary'
Plug 'sbdchd/neoformat'

Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'

call plug#end()

colorscheme codedark

let mapleader = " "
" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

nnoremap <leader>ps :lua require('telescope.builtin').grep_string({ search = vim.fn.input("Grep for > ") }) <cr>
nnoremap <c-p> <cmd>Telescope find_files<cr>

" kassio/neoterm
let g:neoterm_default_mod = 'vertical'
let g:neoterm_size = 60
let g:neoterm_autoinsert = 1
nnoremap <c-t> :Ttoggle<CR>
inoremap <c-t> <Esc>:Ttoggle<CR>
tnoremap <c-t> <c-\><c-n>:Ttoggle<CR>

" sbdchd/neoformat
nnoremap <leader>F :Neoformat prettier<CR>

" tpope/vim-fugitive
nnoremap <leader>gg :G<CR>

lua require("gnarus")
