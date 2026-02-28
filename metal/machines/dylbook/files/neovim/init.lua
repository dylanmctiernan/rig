-- Simple Neovim configuration (converted from init.vim)

-- Options
vim.opt.background = 'dark'
vim.opt.clipboard = 'unnamedplus'
vim.opt.completeopt = 'noinsert,menuone,noselect'
vim.opt.cursorline = true
vim.opt.hidden = true
vim.opt.inccommand = 'split'
vim.opt.mouse = 'a'
vim.opt.number = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.title = true
vim.opt.ttimeoutlen = 0
vim.opt.wildmenu = true

-- Show whitespace
vim.opt.list = true
vim.opt.listchars = { tab = '>·', space = '·', trail = '·' }

-- Whitespace highlight color
vim.cmd([[highlight SpecialKey ctermfg=Grey guifg=#555555]])

-- Tab settings
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
