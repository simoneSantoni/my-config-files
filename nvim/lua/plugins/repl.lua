return {
  "jpalardy/vim-slime",
  init = function()
    vim.g.slime_no_mappings = 0
    vim.g.slime_target = "neovim"
    vim.g.slime_python_ipython = 1
  end,
}
