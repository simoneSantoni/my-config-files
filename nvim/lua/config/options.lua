-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Command-line completion
vim.opt.wildmode = "longest:full,full"
vim.opt.wildmenu = true

-- Neovide settings (disable effects)
if vim.g.neovide then
  vim.g.neovide_cursor_vfx_mode = ""
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_cursor_trail_size = 0
  vim.g.neovide_scroll_animation_length = 0
  vim.g.neovide_floating_blur_amount_x = 0
  vim.g.neovide_floating_blur_amount_y = 0
end
