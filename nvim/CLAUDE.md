# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a LazyVim-based Neovim configuration. LazyVim is a Neovim setup powered by lazy.nvim that provides sensible defaults and a modular plugin architecture.

## Architecture

- `init.lua` - Entry point, loads `config.lazy`
- `lua/config/` - Core configuration: `lazy.lua` (bootstrap), `options.lua` (loaded before plugins), `keymaps.lua` (loaded on VeryLazy event)
- `lua/plugins/` - Plugin specifications (auto-loaded by lazy.nvim, each file returns a table of plugin specs)
- `lazyvim.json` - LazyVim extras: nvim-cmp, git, json, markdown, python, r, sql, tex, yaml
- `queries/` - Custom treesitter queries (taskjuggler)

### Plugin Configuration Pattern

When extending a LazyVim plugin, always guard against nil opts:

```lua
return {
  {
    "plugin/name",
    opts = function(_, opts)
      opts = opts or {}  -- Always guard against nil opts
      -- modify opts
    end,
  },
}
```

### Key Plugin Interactions

The Quarto/R/REPL stack has interdependencies that are important to understand:

1. **quarto-nvim** (`quarto.lua`) depends on **otter.nvim** (`otter.lua`) for embedded language support in code cells (R, Python, bash)
2. **vim-slime** (`quarto.lua`) is the default REPL sender; **molten-nvim** is an alternative that can be toggled at runtime (`<localleader>mi` / `<localleader>md`), which swaps the quarto codeRunner method
3. **jupytext.nvim** (`quarto.lua`) converts `.ipynb` files to `.qmd` format transparently
4. **Zotero citations** (`completions.lua`) require zotcite as a top-level plugin (not just a dependency) so its ftplugin/ files are sourced, which start the zotero_ls LSP. Custom autocmds trigger cmp on `@` in markdown/quarto and `{` after `\cite` in tex

### Formatting

Configured via conform.nvim (`conform.lua`) with format-on-save:
- Lua: stylua
- Python: isort + black (chained)
- JavaScript: prettierd with prettier fallback
- Julia: runic (custom binary at `/home/simon/.local/bin/runic`)
- Manual format: `<leader>m`

### Colorscheme

- **Terminal**: yaru (from `simoneSantoni/yaru.nvim`), transparent background
- **Neovide**: github_dark (from github-nvim-theme), yaru is skipped
- Many alternatives lazy-loaded, switchable with `:colorscheme`

## System Dependencies

| Feature | Dependencies |
|---------|-------------|
| Formatting | stylua, black, isort, prettier/prettierd |
| Julia formatting | Julia + Runic binary at `~/.local/bin/runic` |
| LaTeX | texlive, zathura, xdotool |
| R support | R (resolved dynamically via PATH) |
| Image rendering | ueberzug, ImageMagick |
| Zotero citations | Zotero with Better BibTeX |
| Jupyter/Molten | Python 3.11+, jupyter, pynvim |

## Known Issues

- **jupytext healthcheck error**: The plugin uses deprecated health API (`report_start`). Harmless -- the plugin works, only the healthcheck fails. Wait for upstream fix.

## Validation

After making changes, open Neovim and check `:Lazy` for plugin errors. Use `:checkhealth` for diagnostics.
