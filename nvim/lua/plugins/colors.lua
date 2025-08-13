return {
  {
    "mathofprimes/nightvision-nvim",
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
    priority = 1000,
    opts = {},
    --config = function(_, opts)
    --  vim.o.termguicolors = true
    --  vim.o.background = "light"
    --  require("kanagawa").setup(opts)
    --  vim.cmd.colorscheme("kanagawa-lotus")
    --end,
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
    "maxmx03/solarized.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function(_, opts)
      vim.o.termguicolors = true
      vim.o.background = "light"
      require("solarized").setup(opts)
      vim.cmd.colorscheme("solarized")
    end,
  },
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    -- lazy = false, -- make sure we load this during startup if it is your main colorscheme
    -- priority = 1000, -- make sure to load this before all the other start plugins
    -- opts = {},
    -- config = function(_, opts)
    --   vim.o.termguicolors = true
    --   vim.o.background = "dark"
    --   vim.cmd("colorscheme github_dark_colorblind")
    -- end,
  },
  {
    "zenbones-theme/zenbones.nvim",
    -- Optionally install Lush. Allows for more configuration or extending the colorscheme
    -- If you don't want to install lush, make sure to set g:zenbones_compat = 1
    -- In Vim, compat mode is turned on as Lush only works in Neovim.
    dependencies = "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
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
    "marko-cerovac/material.nvim",
  },
}
