return {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function ()
            require("nvim-treesitter.configs").setup({
                sync_install = true,
                ensure_installed = {
                    "html",
                    "latex",
                    "markdown",
                    "markdown_inline",
                    "yaml",
                },
                highlight = {
                    enable = true,
                },
                indent = {
                    enable = true,
                },
            })
            vim.o.foldmethod = "expr"
            vim.o.foldexpr = "nvim_treesitter#foldexpr()"
            vim.o.foldenable = false
        end
    }
