return require('packer').startup(function(use)
  use ('wbthomason/packer.nvim')
  use ('folke/tokyonight.nvim')
  use { "rose-pine/neovim", name = "rose-pine" }
  use {
     "ThePrimeagen/harpoon",
    branch = "harpoon2",
    requires = { {"nvim-lua/plenary.nvim"} }
    }
 use {
     'nvim-telescope/telescope.nvim', tag = '0.1.5',
 -- or  branch = '0.1.x',
      requires = { 'nvim-lua/plenary.nvim' }
  }
 use { 'mfussenegger/nvim-lint' }
 use { 'mhartington/formatter.nvim' }
 use { 'mbbill/undotree' }
 use { 'tpope/vim-fugitive'}
 use {'nvim-treesitter/nvim-treesitter'}

 use {
  'VonHeikemen/lsp-zero.nvim',
  branch = 'v3.x',
  requires = {
    --- Uncomment these if you want to manage LSP servers from neovim
     {'williamboman/mason.nvim'},
     {'williamboman/mason-lspconfig.nvim'},

    -- LSP Support
    {'neovim/nvim-lspconfig'},
    -- Autocompletion
    {'hrsh7th/nvim-cmp'},
    {'hrsh7th/cmp-nvim-lsp'},
    {'L3MON4D3/LuaSnip'},
  }
}
use {'christoomey/vim-tmux-navigator'}


  -- Put this at the end after all plugins
end)

