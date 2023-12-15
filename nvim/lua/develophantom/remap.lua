local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

vim.g.mapleader = " "

keymap("n", "<leader>h", ":set hlsearch!<CR>", opts)
keymap("n", "<leader>q", ":q<CR>", opts)
keymap("n", "<leader>w", ":w<CR>", opts)
keymap("i", "jk", "<ESC>", opts)
keymap("v","jk", "<ESC>", opts)

vim.keymap.set("n","<leader>pv",vim.cmd.Ex)


-- split screen and move between them
-- keymap.set("n","<leader>v", ":vsplit<CR><C-w>l", opts)
-- keymap.set("n","<leader>h", ":hsplit<CR><C-w>j", opts)
-- map.set("n","<leader>l", "<wincmd h<CR>", opts)
-- map.set("n","<leader>l", "<C-w>h<CR>", opts)
-- map.set("n","<leader>j", "<C-w>j<CR>", opts)

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
