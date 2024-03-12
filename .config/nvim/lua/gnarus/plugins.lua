local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

local packer_bootstrap
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim',
    install_path })
  vim.cmd [[packadd packer.nvim]]
end

local ok, packer = pcall(require, "packer")
if not ok then
  return
end

return packer.startup(function(use)
  use 'wbthomason/packer.nvim'

  use { 'goolord/alpha-nvim', requires = { 'kyazdani42/nvim-web-devicons' } }

  use 'folke/tokyonight.nvim'

  use 'tpope/vim-surround'

  use { 'nvim-lualine/lualine.nvim', requires = { 'kyazdani42/nvim-web-devicons', opt = true } }

  use { 'kyazdani42/nvim-tree.lua', requires = { 'kyazdani42/nvim-web-devicons' } }

  use 'numToStr/Comment.nvim'
  use 'JoosepAlviste/nvim-ts-context-commentstring'

  use 'tpope/vim-fugitive'
  use 'lewis6991/gitsigns.nvim'

  use 'ThePrimeagen/harpoon'

  use { 'nvim-telescope/telescope.nvim', requires = { 'nvim-lua/plenary.nvim' } }
  use 'windwp/nvim-spectre'

  use {
    -- LSP Support
    'neovim/nvim-lspconfig',
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',

    -- Autocompletion
    'hrsh7th/nvim-cmp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'saadparwaiz1/cmp_luasnip',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-nvim-lua',

    -- Snippets
    'L3MON4D3/LuaSnip',
    'rafamadriz/friendly-snippets',
  }
  use { 'David-Kunz/cmp-npm', requires = { 'nvim-lua/plenary.nvim' } }

  use "b0o/schemastore.nvim"

  use { "rcarriga/nvim-dap-ui", requires = { "mfussenegger/nvim-dap" } }
  use 'theHamsta/nvim-dap-virtual-text'

  use 'nvimtools/none-ls.nvim'
  use 'jose-elias-alvarez/typescript.nvim'

  use { 'nvim-treesitter/nvim-treesitter', run = ":TSUpdate" }
  use 'nvim-treesitter/nvim-treesitter-context'
  use 'nvim-treesitter/playground'
  use 'mbbill/undotree'

  use 'gnarus-g/ts-node-jumps.nvim'
  use 'gnarus-g/rested.vim'

  -- for yuck and other lisp like languages
  -- auto balance parentheses
  use 'gpanders/nvim-parinfer'

  use {
    "ThePrimeagen/refactoring.nvim",
    requires = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" }
    }
  }

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
