-- Minimal Neovim config for running tests with mini.test
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Add plugin source to runtimepath
vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- Add mini.nvim to runtimepath
vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/deps/mini.nvim")

-- Set up mini.test
require("mini.test").setup()
