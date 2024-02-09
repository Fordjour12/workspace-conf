local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }
local keymapSet = vim.keymap.set

vim.g.mapleader = " "

-- color scheme
--vim.cmd.colorscheme('tokyonight')
vim.cmd.colorscheme('rose-pine')
vim.api.nvim_set_hl(0,'Normal', {bg = 'none'})
vim.api.nvim_set_hl(0,'NormalFloat', {bg = 'none'})

-- end of color scheme

keymap("n", "<leader>h", ":set hlsearch!<CR>", opts)
keymap("n", "<leader>q", ":q<CR>", opts)
keymap("n", "<leader>w", ":w<CR>", opts)
keymap("i", "jk", "<ESC>", opts)
keymap("v","jk", "<ESC>", opts)

keymapSet("n","<leader>pv",vim.cmd.Ex)


-- split screen and move between them
keymapSet("n","<leader>v", ":vsplit<CR><C-w>l", opts)
keymapSet("n","<leader>h", ":hsplit<CR><C-w>j", opts)


-- opt settings
vim.opt.guicursor = ""

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.breakindent = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.config/nvim/undodir"

vim.opt.termguicolors = true

vim.opt.scrolloff = 10
vim.opt.updatetime = 500
vim.opt.colorcolumn = "100"
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"


-- colorscheme
