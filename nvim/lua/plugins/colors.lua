return {
  {
    "mathofprimes/nightvision-nvim",
    config = function()
      vim.cmd.colorscheme("nightvision")
    end,
  },
  {
    "LazyVim/LazyVim",
  },

  {
    "EdenEast/nightfox.nvim",
  },

  {
    "gustavoprietop/doom-themes.nvim",
  },

  {
    "scottmckendry/cyberdream.nvim",
  },

  {
    "rebelot/kanagawa.nvim",
  },

  {
    "nlknguyen/papercolor-theme",
  },

  {
    "whatyouhide/vim-gotham",
  },
  {
    "Mofiqul/vscode.nvim",
  },
  {
    "rose-pine/neovim",
  },
  {
    "bluz71/vim-moonfly-colors",
  },
  {
    "craftzdog/solarized-osaka.nvim",
  },
  {
    "zenbones-theme/zenbones.nvim",
    -- Optionally install Lush. Allows for more configuration or extending the colorscheme
    -- If you don't want to install lush, make sure to set g:zenbones_compat = 1
    -- In Vim, compat mode is turned on as Lush only works in Neovim.
    dependencies = "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
    -- you can set set configuration options here
    -- config = function()
    --     vim.g.zenbones_darken_comments = 45
    --     vim.cmd.colorscheme('zenbones')
    -- end
  },
  {
    "zenbones-theme/zenbones.nvim",
    -- Optionally install Lush. Allows for more configuration or extending the colorscheme
    -- If you don't want to install lush, make sure to set g:zenbones_compat = 1
    -- In Vim, compat mode is turned on as Lush only works in Neovim.
    dependencies = "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
    -- you can set set configuration options here
    -- config = function()
    --     vim.g.zenbones_darken_comments = 45
    --     vim.cmd.colorscheme('zenbones')
    -- end
  },
}
