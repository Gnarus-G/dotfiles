local ok, packer = pcall(require, "packer")
if not ok then
  return
end

return packer.startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'nvim-lua/plenary.nvim'

  use 'folke/tokyonight.nvim'

  use 'christoomey/vim-tmux-navigator'

  use 'tpope/vim-surround'

  use { 'nvim-lualine/lualine.nvim', requires = { 'kyazdani42/nvim-web-devicons', opt = true } }

  use { 'kyazdani42/nvim-tree.lua', requires = { 'kyazdani42/nvim-web-devicons' } }

  use { 'akinsho/bufferline.nvim', tag = "v2.*", requires = 'kyazdani42/nvim-web-devicons' }

  use 'numToStr/Comment.nvim'
  use 'JoosepAlviste/nvim-ts-context-commentstring'

  use "windwp/nvim-autopairs"

  use 'tpope/vim-fugitive'
  use 'lewis6991/gitsigns.nvim'

  use 'nvim-telescope/telescope.nvim'

  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-cmdline'
  use 'saadparwaiz1/cmp_luasnip'

  use 'L3MON4D3/LuaSnip'
  use 'rafamadriz/friendly-snippets'

  use 'neovim/nvim-lspconfig'
  use "williamboman/nvim-lsp-installer"

  use 'jose-elias-alvarez/null-ls.nvim'

  use 'nvim-treesitter/nvim-treesitter'
end)
