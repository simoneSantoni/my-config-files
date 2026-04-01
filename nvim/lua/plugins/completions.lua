return {
  -- Zotcite must be a top-level plugin (not just a dependency) so that its
  -- ftplugin/ files are sourced. Those ftplugins start zotcite's built-in
  -- LSP server (zotero_ls) which provides citation completions after @.
  -- The LSP does not declare trigger characters, so we add autocmds to
  -- manually trigger cmp: "@" in markdown/quarto, "{" after \cite in tex.
  {
    "jalvesaq/zotcite",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim",
    },
    ft = { "markdown", "quarto", "rmd", "pandoc", "tex", "rnoweb", "typst", "vimwiki" },
    config = function()
      local function trigger_cmp()
        vim.defer_fn(function()
          local cmp = require("cmp")
          if not cmp.visible() then
            cmp.complete()
          end
        end, 100)
      end

      -- Markdown/Quarto: trigger on @
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "quarto", "rmd", "pandoc" },
        callback = function()
          vim.api.nvim_create_autocmd("InsertCharPre", {
            buffer = 0,
            callback = function()
              if vim.v.char == "@" then trigger_cmp() end
            end,
          })
        end,
      })

      -- LaTeX/Rnoweb: trigger on { when preceded by \cite variants
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "tex", "rnoweb" },
        callback = function()
          vim.api.nvim_create_autocmd("InsertCharPre", {
            buffer = 0,
            callback = function()
              if vim.v.char == "{" then
                local col = vim.fn.col(".") - 1
                local line = vim.fn.getline("."):sub(1, col)
                if line:match("\\cite%S*$") then trigger_cmp() end
              end
            end,
          })
        end,
      })
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    enabled = true,
    dependencies = {
      "R-nvim/cmp-r",
    },
    opts = function(_, opts)
      opts = opts or {}
      opts.sources = opts.sources or {}
      table.insert(opts.sources, { name = "cmp_r" })
    end,
  },
}
