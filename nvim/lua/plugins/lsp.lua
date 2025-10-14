return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    opts = {
      servers = {
        -- Disabled to suppress warning. Uncomment and install via :MasonInstall yaml-language-server if needed
        -- yamlls = {
        --   settings = {
        --     yaml = {
        --       schemas = {
        --         ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        --       },
        --     },
        --   },
        -- },
      },
    },
  },
}
