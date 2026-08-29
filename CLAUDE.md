# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Dotfiles repository for a Linux desktop environment running i3 window manager with Ubuntu Yaru theming. Focused on scientific writing and data analysis workflows (Quarto, R, Python, Julia, LaTeX). See `README.md` for full component list and installation instructions.

## Component-Specific Guidance

These subdirectories have detailed `CLAUDE.md` files with architecture and commands:
- `nvim/` — LazyVim configuration. See `nvim/CLAUDE.md` for plugin interaction details (Quarto/otter/slime stack, Zotero citation wiring, colorscheme logic)
- `neomutt/` — Gmail email client. See `neomutt/CLAUDE.md` for testing commands and keybindings
- `emacs/` — GNU Emacs 30 (`init.el`, package.el). See `emacs/CLAUDE.md` for load-order rationale and the pdf-tools/vterm/claude-code-ide build dependencies
- `hhkb/` — HHKB Studio keymap profiles managed with `hhkb-studio-tools`. See `hhkb/CLAUDE.md` for the USB-only config-access gotcha (Bluetooth returns garbage), how to find the vendor hidraw interface, and the bottom-row cell map

## Reloading Configs After Changes

| Component | Reload Command |
|-----------|----------------|
| neovim | Restart nvim or `:Lazy reload` |
| neomutt | Restart neomutt |
| neovide | Close and reopen |
| zsh | `source ~/.zshrc` |
| emacs | Restart Emacs, or `M-x load-file` on `init.el` |
| ghostty | `<C-S-,>` in a running Ghostty (reloads config + theme) |

## Symlink Deployment

Configs are symlinked from this repo to `~/.config/` (use
`scripts/link-configs.sh`, which also backs up whatever it replaces):
```bash
for dir in nvim neomutt neovide fastfetch ghostty; do
  ln -sf $(pwd)/$dir ~/.config/$dir
done
ln -sf "$(pwd)/zsh/.zshrc" ~/.zshrc
ln -sf "$(pwd)/emacs/init.el" ~/.emacs.d/init.el
```

Emacs is symlinked as a single file (`init.el`), not a directory, because
`~/.emacs.d/` also holds generated state (`elpa/`, `eln-cache/`, …) that is not
tracked in this repo.

## Shell Environment (.zshrc)

The `.zshrc` lives in the `zsh/` subdirectory (symlinked to `~/.zshrc`).

- **Oh-My-Zsh plugins**: git, zsh-syntax-highlighting, zsh-autosuggestions, zsh-history-substring-search
- **Zinit**: Additional plugin manager for zsh-completions (auto-installs if missing)
- **Key aliases**: `vim`/`vi` → nvim, `neomutt` → launches with `TERM=xterm-direct` for color support
- **Language toolchains**: conda/Miniconda (Python/R), juliaup (Julia), nvm (Node.js)
- **Extra PATH entries**: Thunderbird, Zotero, Neovim, Kitty, `~/.local/bin`
- **Hardcoded username**: PATH entries in `.zshrc` use `/home/simon/` — update these when deploying on a different machine

## Theme Consistency

Two schemes, split by application — check which one a component belongs to
before changing any color.

**Ubuntu Yaru** (dark) — nvim, neomutt, neovide:
- Background: `#2C001E` / `#300a24`
- Foreground: `#F6F5F4` / `#eeeeec`
- Accent: `#E95420` (Ubuntu orange)
- Font: UbuntuMono Nerd Font / FiraCode Nerd Font

**ef-elea-light** (light) — emacs, mc, ghostty:
- Background: `#edf5e2` (bg-main)
- Foreground: `#221321` (fg-main)
- Accent: `#770080` (cursor magenta)
- Font: JuliaMono Nerd Font Mono

The ef-elea-light ports are hand-derived from ef-themes 2.2.0
(`~/.emacs.d/elpa/ef-themes-*/ef-elea-light-theme.el` is the source of truth for
the palette). `mc/skins/ef-elea-light.ini` and `ghostty/themes/ef-elea-light`
must be kept in sync with each other when the palette changes.

## Verification Commands

```bash
# Check neomutt config syntax
neomutt -D 2>&1 | head -20

# Check nvim health
nvim --headless "+checkhealth" "+qa"

# Verify zsh loads without errors
zsh -i -c exit
```
