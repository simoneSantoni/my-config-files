# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a LazyVim-based Neovim configuration focused on scientific and academic writing, particularly for literate programming with Quarto/Jupyter notebooks, R, Python, Julia, and LaTeX. The configuration emphasizes REPL-driven development and academic citation management.

## Architecture

### Plugin System

The configuration uses lazy.nvim as the plugin manager, bootstrapped in `lua/config/lazy.lua`. Plugins are loaded from:
- LazyVim base plugins (imported automatically)
- Custom plugins in `lua/plugins/*.lua` (each file returns a plugin spec)

### Configuration Structure

```
init.lua                    -- Entry point, loads config.lazy
lua/config/
  ├── lazy.lua             -- Plugin manager setup
  ├── options.lua          -- Vim options (extends LazyVim defaults)
  ├── keymaps.lua          -- Custom keymaps (extends LazyVim defaults)
  └── autocmds.lua         -- Autocommands (extends LazyVim defaults)
lua/plugins/               -- Plugin specifications (auto-loaded by lazy.nvim)
```

### Core Functionality Areas

**Literate Programming & Scientific Computing**
- `quarto.lua`: Central plugin for Quarto document support, integrates with otter.nvim for embedded language features
- `otter.nvim`: Provides LSP features for code chunks in Quarto/markdown (LSP disabled, used only for syntax)
- `jupytext.nvim`: Auto-converts Jupyter notebooks to .qmd format on open/save
- `molten-nvim`: Alternative code execution backend for notebooks (can replace slime)

**REPL Integration**
- `vim-slime`: Default code execution method, sends code to Neovim terminal
- Custom REPL keymaps in `lua/config/keymaps.lua`:
  - `<C-,><C-,>`: Send paragraph to REPL
  - `<C-.><C-.>`: Send line to REPL
- Special handling for Python/IPython via `SlimeOverride_EscapeText_quarto()` in `quarto.lua`

**Academic Citation Management**
- `zotcite.lua`: Zotero integration for citation insertion
- `telescope-zotero.lua`: Telescope extension for searching Zotero library
- Both depend on external Zotero installation

**Language Support**
- Julia: `julia.lua` (julia-vim syntax)
- R: LazyVim extra + REPL integration
- Python: LazyVim extra + IPython REPL support
- LaTeX: `tex.lua` (vimtex with zathura viewer)

**Code Formatting**
- `conform.lua`: Defines formatters per filetype (manual format: `<leader>m`)
  - Lua: stylua
  - Python: isort + black (runs sequentially)
  - Julia: runic (custom formatter definition using Julia REPL)
  - JavaScript: prettierd/prettier (stops after first successful formatter)

## LazyVim Extras

The configuration uses several LazyVim extras (defined in `lazyvim.json`), which provide pre-configured plugin bundles:
- Languages: python, r, markdown, json, yaml, tex, sql, toml, thrift
- Coding: luasnip, yanky, mini-comment, mini-snippets
- Editor: telescope, fzf, harpoon2, dial, inc-rename, mini-diff
- Formatting: black, prettier
- UI: treesitter-context
- Utilities: git, gitui, dot, mini-hipatterns
- VSCode: vscode (VSCode compatibility layer)

## Common Development Tasks

### Testing Configuration Changes

Neovim configuration is live-loaded. After editing Lua files:
1. Either restart Neovim or source the file: `:source %`
2. For plugin changes: `:Lazy reload <plugin-name>`
3. Check for errors: `:messages` or `:checkhealth`

### Managing Plugins

```vim
:Lazy                    " Open plugin manager UI
:Lazy sync              " Install/update/clean plugins
:Lazy check             " Check for updates
:Lazy profile           " View startup performance
```

### Adding a New Plugin

1. Create a new file in `lua/plugins/` (e.g., `lua/plugins/myplugin.lua`)
2. Return a plugin spec table:
```lua
return {
  "username/plugin-name",
  opts = {
    -- plugin options
  },
}
```
3. Restart Neovim or run `:Lazy reload`

### Modifying Existing Plugins

Plugin files can override LazyVim defaults by returning a spec with the same plugin name. The opts table is merged with defaults.

### Keymapping Conventions

- `<leader>` is typically space (LazyVim default)
- `<localleader>` is used for filetype-specific bindings (often backslash)
- REPL bindings use `<C-,>` and `<C-.>` prefix
- Molten (notebook) bindings use `<localleader>m` prefix
- Terminal escape: `<Esc>` exits terminal mode

## Special Considerations

### Quarto Code Execution

The config supports two code execution backends:
1. **vim-slime** (default): Sends code to a Neovim terminal running REPL
2. **molten-nvim**: Inline output rendering (toggle with `<localleader>mi`/`md`)

When switching between them, the `quarto.config.codeRunner.default_method` changes dynamically.

### Python/IPython Integration

The `SlimeOverride_EscapeText_quarto()` function in `quarto.lua` automatically detects Python chunks and uses `%cpaste -q` for multi-line code to IPython, ensuring proper indentation handling.

### Julia Formatting

The Runic formatter is invoked via Julia REPL (`julia --project=@runic`), so the Runic.jl package must be installed in the `@runic` environment.

### LaTeX/PDF Viewing

vimtex is configured to use zathura as the PDF viewer (`vim.g.vimtex_view_method = "zathura"`). Change this in `lua/plugins/tex.lua` if using a different viewer.

## Troubleshooting

### LSP Issues in Code Chunks

If LSP features aren't working in Quarto code chunks, check:
1. Language is listed in `quarto.lua` opts.lspFeatures.languages
2. Corresponding treesitter parser is installed (see `treesitter.lua`)
3. LSP server for the language is installed (via Mason or system package manager)

### REPL Not Responding

1. Verify terminal is running the correct REPL (Python → ipython, R → R, Julia → julia)
2. Use `<leader>cm` to display the terminal job_id and `<leader>cs` to configure slime target
3. Check `vim.g.slime_target` is set to "neovim" (default in `quarto.lua`)

### YAML Language Server Warning

If you see "WARNING `yaml-language-server` not found", install it via Mason:
```vim
:Mason
" Search for yaml-language-server and install it
```
Or ignore if you don't need YAML completion in Quarto files.

### Image Pasting Not Working

The img-clip plugin requires clipboard support and system utilities (xclip on Linux). Verify:
```bash
:checkhealth img-clip
```

### ueberzugpp Missing OpenCV Libraries

If you see `libopencv_imgcodecs.so.412: cannot open shared object file`, the conda-installed ueberzugpp has a version mismatch with OpenCV libraries. Fix by creating symlinks:
```bash
cd ~/miniconda3/lib
ln -sf libopencv_imgcodecs.so.411 libopencv_imgcodecs.so.412
ln -sf libopencv_imgproc.so.411 libopencv_imgproc.so.412
ln -sf libopencv_core.so.411 libopencv_core.so.412
```
