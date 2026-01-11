# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a LazyVim-based Neovim configuration. LazyVim is a Neovim setup powered by lazy.nvim that provides sensible defaults and a modular plugin architecture.

## Architecture

### Directory Structure

- `init.lua` - Entry point, loads `config.lazy`
- `lua/config/` - Core configuration
  - `lazy.lua` - lazy.nvim bootstrap and plugin loader setup
  - `options.lua` - Vim options (loaded before plugins)
  - `keymaps.lua` - Custom keymaps (loaded on VeryLazy event)
- `lua/plugins/` - Plugin specifications (auto-loaded by lazy.nvim)
- `lazyvim.json` - LazyVim extras configuration and version tracking

### Plugin Configuration Pattern

Each file in `lua/plugins/` returns a table of plugin specs. To extend a LazyVim plugin:

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

### Enabled LazyVim Extras

Configured in `lazyvim.json`: nvim-cmp, git, json, markdown, python, r, sql, tex, yaml.

## Key Customizations

- **Completion**: Uses nvim-cmp (via extras) with sources for R (cmp-r) and Zotero citations (cmp_zotcite)
- **Quarto/R workflow**: quarto-nvim, vim-slime for REPL interaction, otter.nvim for embedded language support
- **REPL keymaps**: `<C-,><C-,>` sends paragraph, `<C-.><C-.>` sends line to REPL
- **Colorscheme**: yaru (active), with many alternatives lazy-loaded
- **Neovide**: All visual effects disabled when running in Neovide

## System Dependencies

Required external tools for full functionality:

| Feature | Dependencies | Install |
|---------|-------------|---------|
| Formatting | stylua, black, isort, prettier | `pip install black isort` / `npm i -g prettier` / `cargo install stylua` |
| Julia formatting | Julia + Runic package | `julia -e 'using Pkg; Pkg.add("Runic")'` |
| LaTeX | texlive, zathura, xdotool | System package manager |
| R support | R | System package manager or conda |
| Image rendering | ueberzug, ImageMagick | `pip install ueberzug` + system ImageMagick |
| Zotero citations | Zotero with Better BibTeX | Manual install |
| Jupyter/Molten | Python 3.11+, jupyter, pynvim | `pip install jupyter pynvim` |

## Known Issues

- **jupytext healthcheck error**: The plugin uses deprecated health API (`report_start`). This is harmless - the plugin works correctly, only the healthcheck fails. Wait for upstream fix.

## Validation

After making changes, open Neovim and check `:Lazy` for plugin errors. Use `:checkhealth` for diagnostics.
