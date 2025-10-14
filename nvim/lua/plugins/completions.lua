return {
  -- otter.nvim is configured in lua/plugins/otter.lua
  {
    "hrsh7th/nvim-cmp",
    enabled = true,
    dependencies = {
      "R-nvim/cmp-r",
    },
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, { name = "cmp_zotcite" })
      table.insert(opts.sources, { name = "cmp_r" })
    end,
  },
}
