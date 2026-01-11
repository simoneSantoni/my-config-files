return {
  {
    "hrsh7th/nvim-cmp",
    enabled = true,
    dependencies = {
      "R-nvim/cmp-r",
      "jalvesaq/zotcite", -- provides cmp_zotcite source
    },
    opts = function(_, opts)
      opts = opts or {}
      opts.sources = opts.sources or {}
      table.insert(opts.sources, { name = "cmp_zotcite" })
      table.insert(opts.sources, { name = "cmp_r" })
    end,
  },
}
