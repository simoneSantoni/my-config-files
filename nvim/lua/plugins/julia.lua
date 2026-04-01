return {

  -- JETLS.jl - Julia LSP server
  -- Install: julia -e 'using Pkg; Pkg.Apps.add(; url="https://github.com/aviatesk/JETLS.jl", rev="release")'
  -- Requires Julia v1.12.2+ and ~/.julia/bin on PATH
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jetls = {
          cmd = { "jetls", "serve" },
          filetypes = { "julia" },
          root_markers = { "Project.toml" },
        },
      },
    },
  },

  -- Conjure - interactive REPL for Julia (and other languages)
  {
    "Olical/conjure",
    ft = { "julia", "python", "r", "lua", "fennel", "lisp", "scheme", "clojure" },
    dependencies = { "PaterJason/cmp-conjure" },
    init = function()
      -- Disable the default mapping to avoid conflicts with existing keymaps
      vim.g["conjure#mapping#prefix"] = "<localleader>"
      -- Use Julia stdio client
      vim.g["conjure#client#julia#stdio#command"] = "julia --project=."
    end,
  },

  -- Add cmp-conjure as a completion source
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts = opts or {}
      opts.sources = opts.sources or {}
      table.insert(opts.sources, { name = "conjure" })
    end,
  },

  -- Ensure Julia treesitter parser is installed
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts = opts or {}
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "julia" })
    end,
  },
}
