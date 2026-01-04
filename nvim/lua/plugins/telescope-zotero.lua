return {
  "jmbuhr/telescope-zotero.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    { "kkharji/sqlite.lua", build = "make" },
  },
  config = function()
    local ok_sqlite = pcall(require, "sqlite.db")
    if not ok_sqlite then
      -- sqlite dependency not ready yet; avoid crashing Lazy startup
      return
    end

    local ok, telescope = pcall(require, "telescope")
    if ok then
      telescope.load_extension("zotero")
    end
  end,
}
