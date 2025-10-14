return {
  "jmbuhr/otter.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    lsp = {
      enabled = false, -- Disable LSP features entirely
    },
    buffers = {
      set_filetype = false,
      write_to_disk = false,
    },
    handle_leading_whitespace = true,
    -- Suppress language detection warnings
    verbose = {
      no_code_found = false,
      ignore_warnings = true,
    },
  },
}
