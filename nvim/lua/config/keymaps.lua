-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Send code to REPL
vim.keymap.set("n", "<C-,><C-,>", "<Plug>SlimeParagraphSend", { desc = "Send paragraph to REPL" })
vim.keymap.set("n", "<C-.><C-.>", "<Plug>SlimeLineSend", { desc = "Send line to REPL" })

-- Leave terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { silent = true })
