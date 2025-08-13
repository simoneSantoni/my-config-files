-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- UI
vim.o.background = "light"
local opt = vim.opt
opt.wrap = true

-- terminal
vim.api.nvim_command("autocmd TermOpen * startinsert") -- starts in insert mode
vim.api.nvim_command("autocmd TermOpen * setlocal norelativenumber") -- no relative numbers
vim.api.nvim_command("autocmd TermOpen * setlocal nonumber") -- no numbers
vim.api.nvim_command("autocmd TermEnter * setlocal signcolumn=no") -- no sign column
