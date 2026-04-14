# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Dotfiles repository for a Linux desktop environment running i3 window manager with Ubuntu Yaru theming. Focused on scientific writing and data analysis workflows (Quarto, R, Python, Julia, LaTeX).

## Component-Specific Guidance

These subdirectories have detailed `CLAUDE.md` files with architecture and commands:
- `nvim/` - LazyVim configuration — see `nvim/CLAUDE.md` for plugin interaction details (Quarto/otter/slime stack, Zotero citation wiring, colorscheme logic)
- `neomutt/` - Gmail email client — see `neomutt/CLAUDE.md` for testing commands and keybindings

## Reloading Configs After Changes

| Component | Reload Command |
|-----------|----------------|
| neovim | Restart nvim or `:Lazy reload` |
| neomutt | Restart neomutt |
| neovide | Close and reopen |
| zsh | `source ~/.zshrc` |

## Shell Environment (.zshrc)

The `.zshrc` lives at repo root (symlinked to `~/.zshrc`); `zsh/` directory contains only a README.

- **Oh-My-Zsh plugins**: git, zsh-syntax-highlighting, zsh-autosuggestions, zsh-history-substring-search
- **Zinit**: Additional plugin manager for zsh-completions (auto-installs if missing)
- **Key aliases**: `vim`/`vi` → nvim, `neomutt` → launches with `TERM=xterm-direct` for color support
- **Language toolchains**: conda/Miniconda (Python/R), juliaup (Julia), nvm (Node.js)
- **Extra PATH entries**: Thunderbird, Zotero, Neovim, R, Spyder

## Symlink Deployment

Configs are symlinked from this repo to `~/.config/`:
```bash
for dir in nvim neomutt neovide fastfetch; do
  ln -sf $(pwd)/$dir ~/.config/$dir
done
ln -sf $(pwd)/.zshrc ~/.zshrc
```

## Theme Consistency

All applications use **Ubuntu Yaru** color scheme:
- Background: `#2C001E` / `#300a24`
- Foreground: `#F6F5F4` / `#eeeeec`
- Accent: `#E95420` (Ubuntu orange)
- Font: UbuntuMono Nerd Font / FiraCode Nerd Font

## Dependencies

Core: Neovim 0.10+, NeoMutt, Neovide, Fastfetch, Oh-My-Zsh, Zinit

Fonts: UbuntuMono Nerd Font, UbuntuSans Nerd Font, FiraCode Nerd Font

Neovim tooling: stylua, black, isort, prettier/prettierd, texlive, zathura, xdotool, ImageMagick, Zotero (Better BibTeX)

NeoMutt tooling: pass (password manager), lynx (HTML email rendering)

Language runtimes: Python/R (conda), Julia (juliaup), Node.js (nvm)

## Verification Commands

```bash
# Check neomutt config syntax
neomutt -D 2>&1 | head -20

# Check nvim health
nvim --headless "+checkhealth" "+qa"
```
