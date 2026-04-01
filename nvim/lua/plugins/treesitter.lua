return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
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
      })
    end,
  },
}
