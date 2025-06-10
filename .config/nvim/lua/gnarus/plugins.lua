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

  use {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    requires = { { "nvim-lua/plenary.nvim" } }
  }

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
    'hrsh7th/cmp-cmdline',
    'saadparwaiz1/cmp_luasnip',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-nvim-lua',
    "onsails/lspkind-nvim",

    -- Snippets
    'L3MON4D3/LuaSnip',
    'rafamadriz/friendly-snippets',
  }
  use { 'David-Kunz/cmp-npm', requires = { 'nvim-lua/plenary.nvim' } }

  use "b0o/schemastore.nvim"

  use { "rcarriga/nvim-dap-ui", requires = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio", "rcarriga/cmp-dap" } }
  use 'theHamsta/nvim-dap-virtual-text'
  use "nvim-telescope/telescope-dap.nvim"

  use 'nvimtools/none-ls.nvim'

  use { 'nvim-treesitter/nvim-treesitter', run = ":TSUpdate" }
  use 'nvim-treesitter/nvim-treesitter-context'
  use 'nvim-treesitter/playground'
  use 'mbbill/undotree'

  use 'gnarus-g/ts-node-jumps.nvim'

  use { 'gnarus-g/restedlang.nvim',
    requires = {
      { "nvim-treesitter/nvim-treesitter", "neovim/nvim-lspconfig" }
    },
    config = function()
      require("restedlang")
    end
  }

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

  use {
    "windwp/nvim-ts-autotag",
    requires = {
      { "nvim-treesitter/nvim-treesitter" }
    },
  }

  use {
    "luckasRanarison/tailwind-tools.nvim",
    run = ":UpdateRemotePlugins",
    requires = {
      {
        "nvim-treesitter/nvim-treesitter",
      }
    }
  }

  use {
    "pmizio/typescript-tools.nvim",
    requires = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
      'dmmulroy/ts-error-translator.nvim' -- optional
    },
    config = function()
      require("ts-error-translator").setup()
    end
  }

  use {
    "Marskey/telescope-sg"
  }

  use 'HakonHarnes/img-clip.nvim'

  use { "echasnovski/mini.diff", }

  use {
    "ravitemer/mcphub.nvim",
    --[[ run = "npm install -g mcp-hub@latest", ]]
    requires = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim'
    }
  }

  use { "folke/snacks.nvim" }

  use {
    "olimorris/codecompanion.nvim",
    branch = 'main',
    requires = {
      'ravitemer/mcphub.nvim',
      "ravitemer/codecompanion-history.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.diff"
    }
  }

  use 'GeorgesAlkhouri/nvim-aider'

  use {
    'yetone/avante.nvim',
    branch = 'main',
    run = 'make',
    requires = {
      'nvim-treesitter/nvim-treesitter',
      "ravitemer/mcphub.nvim",
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'MeanderingProgrammer/render-markdown.nvim',
      'folke/snacks.nvim'
    }
  }

  use { 'milanglacier/minuet-ai.nvim', }

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
