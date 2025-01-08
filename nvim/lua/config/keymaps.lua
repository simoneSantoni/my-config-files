-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Send code to REPL
vim.cmd("nmap <c-,><c-c> <Plug>SlimeParagraphSend")
vim.cmd("nmap <c-.><c-l> <Plug>SlimeLineSend")

-- Leave terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { silent = true })
