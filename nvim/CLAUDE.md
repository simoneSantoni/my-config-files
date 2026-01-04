# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **LazyVim-based Neovim configuration** specialized for scientific computing, data analysis, and literate programming. It extends LazyVim's base functionality with deep integrations for Quarto, Jupyter notebooks, R, Julia, Python, and LaTeX workflows.

## Architecture

### Plugin System: lazy.nvim

- **Bootstrap location**: `lua/config/lazy.lua`
- Automatically clones lazy.nvim on first run with error handling
- **Version strategy**: Uses latest git commits (`version = false`) except for stability-critical plugins (e.g., molten-nvim uses `version = "^1.0.0"`)
- Custom plugins load at startup by default (`lazy = false` in defaults)
- Update checker enabled but notifications disabled

### Configuration Structure

```
lua/
├── config/               # Core configuration (extends LazyVim defaults)
│   ├── lazy.lua         # Plugin manager setup
│   ├── options.lua      # Additional vim options beyond LazyVim
│   ├── keymaps.lua      # Custom keybindings only
│   └── autocmds.lua     # Custom autocommands
└── plugins/             # Modular plugin configurations (28+ files)
    ├── quarto.lua       # Quarto + jupytext + vim-slime + img-clip + nabla + molten
    ├── molten.lua       # Jupyter kernel integration
    ├── lsp.lua          # Language server configuration
    ├── treesitter.lua   # Syntax highlighting
    └── ...              # One file per domain/feature
```

**Important**: Each file in `lua/plugins/` returns a Lua table (or array of tables) that lazy.nvim automatically loads. Multiple related plugins can be grouped in a single file.

### Plugin Organization Philosophy

- **Modular by domain**: Plugins grouped by functionality (e.g., `quarto.lua` contains all literate programming tools)
- **Extension over override**: Uses `opts` function pattern to extend parent configs rather than replacing them
- **Explicit dependencies**: Comments document cross-plugin relationships (see `quarto.lua:3-4`, `completions.lua:2`)
- **Lazy loading**: Uses `ft` (filetype), `event`, `keys` triggers for on-demand loading

## Key Integration Patterns

### 1. Literate Programming Stack (Quarto/Jupyter)

**Central file**: `lua/plugins/quarto.lua`

**Dependency chain**:
```
quarto.nvim → otter.nvim → treesitter → LSP
         ↓
  jupytext.nvim (converts .ipynb ↔ .qmd)
         ↓
  vim-slime OR molten-nvim (code execution)
```

**Critical details**:
- `quarto.nvim` requires `treesitter.lua` and `lsp.lua` for language features (see comment on line 3)
- `otter.nvim` provides multi-language context awareness in code chunks
- **Code execution backends** are swappable:
  - Default: `vim-slime` (sends to terminal/REPL)
  - Alternative: `molten-nvim` (inline Jupyter kernel with image output)
  - Switch via `quarto_cfg.codeRunner.default_method = "slime"` or `"molten"`
- Jupytext converts notebooks to Quarto format on open (`.ipynb` → `.qmd`)

### 2. REPL Integration

**Keybindings** (defined in `lua/config/keymaps.lua`):
- `<C-,><C-,>`: Send paragraph to REPL (vim-slime)
- `<C-.><C-.>`: Send line to REPL (vim-slime)
- `<localleader>mi`: Initialize molten
- `<localleader>md`: Stop molten
- `<Esc>` in terminal mode: Exit to normal mode

**Custom slime behavior**: The `SlimeOverride_EscapeText_quarto` function (in `quarto.lua:67-78`) automatically uses `%cpaste` for multi-line Python code in IPython.

### 3. Citation Workflow

- `telescope-zotero.lua`: Browse Zotero library
- `citations.lua`: Citation insertion
- `completions.lua`: Adds `cmp_zotcite` source for autocomplete

## Adding Plugins

**Pattern**:
1. Create `lua/plugins/feature-name.lua`
2. Return a table (or array) with lazy.nvim spec:
   ```lua
   return {
     {
       "author/plugin-name",
       dependencies = { "other/plugin" },
       ft = { "markdown", "quarto" },  -- Load on filetype
       opts = {
         setting = "value"
       },
       config = function(_, opts)
         require("plugin").setup(opts)
       end
     }
   }
   ```
3. Restart Neovim (lazy.nvim auto-loads files in `lua/plugins/`)

**Extending existing plugins**: Use `opts` function to merge with parent config:
```lua
opts = function(_, opts)
  opts.sources = opts.sources or {}
  table.insert(opts.sources, { name = "new_source" })
end
```

## Customization Guidelines

### Options & Keymaps
- **Don't override LazyVim defaults** unless necessary
- `lua/config/options.lua` only contains **additions** to LazyVim's options
- `lua/config/keymaps.lua` only contains **custom** mappings
- See LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/

### Autocmds
- Can add custom autocommands in `lua/config/autocmds.lua`
- LazyVim's autocmds use `lazyvim_*` prefixed groups (can reference but don't modify)
- See docs: https://lazyvim.github.io/configuration/general#auto-commands

### Adding Language Support
1. Check if LazyVim extra exists: https://www.lazyvim.org/extras
2. Enable via `:LazyExtras` command (auto-updates `lazyvim.json`)
3. For custom LSP/treesitter setup, extend `lua/plugins/lsp.lua` or `lua/plugins/treesitter.lua`

## LazyVim Extras Enabled

See `lazyvim.json` for active extras. Currently includes:
- Languages: Python, R, JSON, Markdown, LaTeX, SQL, TOML, YAML
- Formatting: Black (Python), Prettier (JS/TS)
- Editor: Telescope, Harpoon2
- Coding: Yanky (clipboard manager)
- UI: VSCode keybindings

## Important Files

- `lazy-lock.json`: Dependency lock file (auto-generated, commit to version control)
- `lazyvim.json`: Active LazyVim extras (auto-generated when using `:LazyExtras`)
- `.neoconf.json`: Neovim LSP configuration (project-specific settings)

## Neovim Commands

- `:Lazy`: Open lazy.nvim UI (view installed plugins, update, sync)
- `:LazyExtras`: Browse and enable LazyVim extras
- `:checkhealth`: Diagnose configuration issues
- `:UpdateRemotePlugins`: Required after installing Python-based plugins (e.g., molten-nvim)

## Testing Changes

**Pattern**: Test in a clean environment
```bash
# Backup current config
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak

# Test changes
ln -s /path/to/test/config ~/.config/nvim
nvim  # Will auto-bootstrap lazy.nvim

# Restore
rm ~/.config/nvim
mv ~/.config/nvim.bak ~/.config/nvim
```

## Plugin Build Requirements

Some plugins need special build steps:
- **molten-nvim**: Requires `:UpdateRemotePlugins` after install (Python plugin)
- **LuaSnip**: Runs `make install_jsregexp` during install (compiles regex engine)
- **Image.nvim**: Terminal with image support (e.g., kitty, wezterm, iTerm2)

## Troubleshooting

1. **Plugin not loading**: Check `:Lazy` UI for errors; ensure dependencies installed
2. **LSP not working**: Run `:LspInfo` and `:checkhealth lsp`
3. **Treesitter errors**: Run `:checkhealth treesitter` and `:TSUpdate`
4. **Molten issues**: Ensure Jupyter kernel installed (`pip install jupyter ipykernel`)
5. **Slime not working**: Check terminal job_id with `<leader>cm` and set target with `<leader>cs`

## Performance Notes

- **Disabled built-in plugins**: gzip, tarPlugin, tohtml, tutor, zipPlugin (see `lua/config/lazy.lua:44-52`)
- **Lazy loading**: Most plugins load on filetype or keymap trigger
- **Startup time**: Check with `nvim --startuptime startup.log`
