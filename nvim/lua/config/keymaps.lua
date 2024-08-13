-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- required in which-key plugin spec in plugins/ui.lua as `require 'config.keymap'`

-- send code to REPL
vim.cmd("nmap <c-,><c-,> <Plug>SlimeParagraphSend")
vim.cmd("nmap <c-.><c-.> <Plug>SlimeLineSend")
