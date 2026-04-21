-- Active colorscheme depends on hostname and neovide
-- Other colorschemes are lazy-loaded and can be activated with :colorscheme <name>
local hostname = vim.uv.os_gethostname()
local is_stellaris = hostname == "stellaris"
local is_t14 = hostname == "t14"
local is_t16 = hostname == "t16"
local is_t490s = hostname == "t490s"
return {
  -- Active colorscheme (yaru, default for non-tuxedo terminal)
  {
    "simoneSantoni/yaru.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      vim.g.yaru_transparent_background = true
      if not vim.g.neovide and (is_t14 or (not is_stellaris and not is_t16 and not is_t490s)) then
        vim.cmd.colorscheme("yaru")
      end
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
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = not is_t490s,
    priority = 1000,
    config = function()
      if is_t490s then
        vim.cmd.colorscheme("github_light")
      end
    end,
  },
  {
    "marko-cerovac/material.nvim",
    lazy = not vim.g.neovide,
    priority = 1000,
    config = function()
      if vim.g.neovide then
        vim.cmd.colorscheme("material")
      end
    end,
  },
  {
    "zenbones-theme/zenbones.nvim",
    dependencies = "rktjmp/lush.nvim",
    lazy = true,
  },
  {
    "simoneSantoni/duotone.nvim",
    lazy = not is_t16,
    priority = 1000,
    config = function()
      if is_t16 and not vim.g.neovide then
        vim.cmd.colorscheme("duotone")
      end
    end,
  },
  {
    "simoneSantoni/meadow.nvim",
    lazy = not is_stellaris,
    priority = 1000,
    config = function()
      if is_stellaris and not vim.g.neovide then
        vim.cmd.colorscheme("meadow")
      end
    end,
  },
}
