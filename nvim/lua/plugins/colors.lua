-- Active colorscheme (yaru)
-- Other colorschemes are lazy-loaded and can be activated with :colorscheme <name>
return {
  -- Active colorscheme
  {
    "simoneSantoni/yaru.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.termguicolors = true
      vim.o.background = "dark"
      vim.cmd.colorscheme("yaru")
      vim.g.yaru_transparent_background = true
    end,
  },

  -- Alternative colorschemes (lazy-loaded, use :colorscheme to switch)
  { "mathofprimes/nightvision-nvim", lazy = true },
  { "EdenEast/nightfox.nvim", lazy = true },
  { "gustavoprietop/doom-themes.nvim", lazy = true },
  { "scottmckendry/cyberdream.nvim", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },
  { "nlknguyen/papercolor-theme", lazy = true },
  { "whatyouhide/vim-gotham", lazy = true },
  { "Mofiqul/vscode.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "bluz71/vim-moonfly-colors", lazy = true },
  { "craftzdog/solarized-osaka.nvim", lazy = true },
  { "maxmx03/solarized.nvim", lazy = true },
  { "projekt0n/github-nvim-theme", name = "github-theme", lazy = true },
  { "marko-cerovac/material.nvim", lazy = true },
  {
    "zenbones-theme/zenbones.nvim",
    dependencies = "rktjmp/lush.nvim",
    lazy = true,
  },
  { "simoneSantoni/duotone.nvim", lazy = true },
}
