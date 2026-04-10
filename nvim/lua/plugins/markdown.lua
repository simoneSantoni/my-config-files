-- Disable marksman LSP - it crashes fatally when markdown files are
-- deleted/moved while nvim is open (known bug in closeDoc -> tryLoad path).
-- The markdown extra still provides render-markdown.nvim and other features.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {
          enabled = false,
        },
      },
    },
  },
}
