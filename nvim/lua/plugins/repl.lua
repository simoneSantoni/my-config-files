return {
  "jpalardy/vim-slime",
  init = function()
    vim.g.slime_no_mappings = 0
    vim.g.slime_target = "neovim"
  end,
}
