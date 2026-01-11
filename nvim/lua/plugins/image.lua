return {
  {
    "3rd/image.nvim",
    build = true,
    event = "VeryLazy",
    cond = function()
      -- Don't load in VS Code or headless mode
      if vim.g.vscode then
        return false
      end
      -- Don't load in headless mode (no terminal available)
      return vim.fn.has("gui_running") == 1 or vim.env.DISPLAY ~= nil or vim.env.WAYLAND_DISPLAY ~= nil
    end,
    opts = {
      backend = "ueberzug",
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki", "quarto" },
        },
        neorg = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "norg" },
        },
        html = { enabled = false },
        css = { enabled = false },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = nil,
      max_height_window_percentage = 50,
      window_overlap_clear_enabled = false,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
      editor_only_render_when_focused = false,
      tmux_show_only_in_active_window = false,
      hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
    },
  },
}
