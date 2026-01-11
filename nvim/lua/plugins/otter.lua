return {
  {
    "jmbuhr/otter.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      buffers = {
        set_filetype = false,
        write_to_disk = false,
      },
      handle_leading_whitespace = true,
    },
  },
}
