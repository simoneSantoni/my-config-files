return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "css",
        "html",
        "latex",
        "markdown",
        "markdown_inline",
        "python",
        "r",
        "scss",
        "svelte",
        "typst",
        "vue",
        "yaml",
      },
      highlight = {
        enable = true,
      },
      indent = {
        enable = true,
      },
    },
  },
}
