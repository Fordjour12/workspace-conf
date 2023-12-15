-- local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- if not vim.loop.fs_stat(lazypath) then
--   vim.fn.system({
--     "git",
--     "clone",
--     "--filter=blob:none",
--     "https://github.com/folke/lazy.nvim.git",
--     "--branch=stable", -- latest stable release
--     lazypath,
--   })
-- end

-- vim.opt.rtp:prepend(lazypath)

-- local plugins={
--     -- your plugins
--     {
--     "folke/tokyonight.nvim",
--     lazy = false, -- make sure we load this during startup if it is your main colorscheme
--     priority = 1000, -- make sure to load this before all the other start plugins
--     config = function()
--       -- load the colorscheme here
--       vim.cmd([[colorscheme tokyonight]])
--     end,
--   },
--   {'VonHeikemen/lsp-zero.nvim',branch = 'v3.x'},
--     --- Uncomment these if you want to manage LSP servers from neovim
--     {'williamboman/mason.nvim'},
--     {'williamboman/mason-lspconfig.nvim'},

--     -- LSP Support
--     {'neovim/nvim-lspconfig'},
--     -- Autocompletion
--     {'hrsh7th/nvim-cmp'},
--     {'hrsh7th/cmp-nvim-lsp'},
--     {'L3MON4D3/LuaSnip'},

-- {'nvim-treesitter/nvim-treesitter'},

-- --'WhoIsSethDaniel/mason-tool-installer.nvim',
-- {
--     'nvim-telescope/telescope.nvim', tag = '0.1.5',
-- -- or                              , branch = '0.1.x',
--       dependencies = { 'nvim-lua/plenary.nvim'
--     }
-- },
-- {
--     "ThePrimeagen/harpoon",
--     branch = "harpoon2",
--     dependencies = { {"nvim-lua/plenary.nvim"} }
-- },
-- { 'mfussenegger/nvim-lint' },
-- { 'mhartington/formatter.nvim' },
-- { 'mbbill/undotree' },
-- { 'tpope/vim-fugitive'},

-- }

-- local opts={
--     -- your config
-- }

-- require("lazy").setup(plugins, opts)
