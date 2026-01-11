# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Dotfiles repository for a Linux desktop environment running i3 window manager with Ubuntu Yaru theming.

## Component-Specific Guidance

These subdirectories have detailed `CLAUDE.md` files with architecture and commands:
- `nvim/` - LazyVim configuration for scientific writing (Quarto, R, Python, Julia)
- `neomutt/` - Gmail email client setup
- `i3/` - Window manager keybindings and configuration
- `polybar/` - Status bar modules and scripts

## Reloading Configs After Changes

| Component | Reload Command |
|-----------|----------------|
| i3 | `i3-msg reload` or `$mod+Shift+c` |
| polybar | `~/.config/polybar/launch.sh` or `polybar-msg cmd restart` |
| dunst | `killall dunst && dunst &` |
| kitty | Close and reopen terminal |
| rofi | Changes apply on next launch |
| zsh | `source ~/.zshrc` |

## Cross-Component Architecture

**i3 → polybar**: i3 config runs `exec_always ~/.config/polybar/launch.sh` on startup. `$mod+p` toggles polybar visibility.

**i3 → rofi**: `$mod+x` launches rofi application launcher.

**polybar scripts**: Located in `polybar/scripts/`, control brightness, screen layout, keyboard layout. Hardcoded monitor names: `eDP` (laptop), `DisplayPort-1` (external).

**polybar → i3**: Some polybar modules execute i3 commands (e.g., workspace switching). Module click actions may run scripts that affect i3.

## Shell Environment (.zshrc)

- **Oh-My-Zsh plugins**: git, zsh-syntax-highlighting, zsh-autosuggestions, zsh-history-substring-search
- **Zinit**: Additional plugin manager for zsh-completions
- **Key aliases**: `vim`/`vi` → nvim, `neomutt` → launches with `TERM=xterm-direct` for color support
- **Language toolchains**: conda (Python/R), juliaup (Julia), nvm (Node.js)

## Symlink Deployment

Configs are symlinked from this repo to `~/.config/`:
```bash
for dir in nvim kitty i3 polybar rofi dunst neomutt zathura neovide fastfetch; do
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

Core: i3-gaps, polybar, rofi, dunst, kitty, Neovim 0.10+, Oh-My-Zsh, Zinit

Fonts: UbuntuMono Nerd Font, UbuntuSans Nerd Font, FiraCode Nerd Font

Utilities: brightnessctl, pactl, xrandr, feh, pass (for neomutt), lynx (HTML email rendering)

## Verification Commands

```bash
# Check i3 config syntax
i3 -C -c ~/.config/i3/config

# Check neomutt config syntax
neomutt -D 2>&1 | head -20

# Test polybar launch
~/.config/polybar/launch.sh

# Test polybar script outputs
~/.config/polybar/scripts/brightness.sh
~/.config/polybar/scripts/keyboard-layout.sh

# Check nvim health
nvim --headless "+checkhealth" "+qa"
```
