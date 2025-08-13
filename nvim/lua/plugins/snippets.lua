return {
  "L3MON4D3/LuaSnip",
  version = "v2.*",
  build = "make install_jsregexp",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  config = function()
    -- This only runs AFTER the plugin is installed
    require("luasnip.loaders.from_vscode").lazy_load()
    require("luasnip").filetype_extend("quarto", { "markdown", "python", "r", "julia" })
  end,
}
