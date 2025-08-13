return {
  "jmbuhr/telescope-zotero.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("telescope").load_extension("zotero")
  end,
}
