return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      -- your other telescope extensions
      -- ...
      {
        "jmbuhr/telescope-zotero.nvim",
        dependencies = {
          { "kkharji/sqlite.lua" },
        },
        -- options:
        -- to use the default opts:
        opts = {},
        -- to configure manually:
        -- config = function
        --   require'zotero'.setup{ <your options> }
        -- end,
      },
    },
    config = function()
      local telescope = require("telescope")
      -- other telescope setup
      -- ...
      telescope.load_extension("zotero")
    end,
  },
}
