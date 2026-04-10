return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts = opts or {}
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, 1, { function() return "" end })
      table.insert(opts.sections.lualine_x, 1, { function() return "" end })
    end,
  },
}
