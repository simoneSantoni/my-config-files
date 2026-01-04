# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Dotfiles repository for a Linux desktop environment running i3 window manager with Ubuntu Yaru theming.

## Repository Structure

```
├── nvim/           # LazyVim-based Neovim config (has its own CLAUDE.md)
├── kitty/          # Kitty terminal emulator
├── i3/             # i3 window manager (has its own CLAUDE.md)
├── polybar/        # Status bar with custom modules (has its own CLAUDE.md)
├── rofi/           # Application launcher
├── dunst/          # Notification daemon
├── neomutt/        # NeoMutt email client for Gmail (has its own CLAUDE.md)
├── zathura/        # PDF viewer
├── neovide/        # Neovim GUI
├── fastfetch/      # System info display
└── .zshrc          # ZSH configuration (Oh-My-Zsh + Zinit)
```

## Component-Specific Guidance

These subdirectories have detailed `CLAUDE.md` files:
- `nvim/` - LazyVim configuration for scientific writing
- `neomutt/` - Gmail email client setup
- `i3/` - Window manager keybindings and configuration
- `polybar/` - Status bar modules and scripts

## Symlink Deployment

Configs are symlinked to `~/.config/`:
```bash
ln -sf $(pwd)/nvim ~/.config/nvim
ln -sf $(pwd)/kitty ~/.config/kitty
ln -sf $(pwd)/i3 ~/.config/i3
ln -sf $(pwd)/polybar ~/.config/polybar
ln -sf $(pwd)/rofi ~/.config/rofi
ln -sf $(pwd)/dunst ~/.config/dunst
ln -sf $(pwd)/neomutt ~/.config/neomutt
ln -sf $(pwd)/zathura ~/.config/zathura
ln -sf $(pwd)/neovide ~/.config/neovide
ln -sf $(pwd)/fastfetch ~/.config/fastfetch
ln -sf $(pwd)/.zshrc ~/.zshrc
```

## Theme Consistency

All applications use **Ubuntu Yaru** color scheme:
- Background: `#2C001E` / `#300a24`
- Foreground: `#F6F5F4` / `#eeeeec`
- Accent: `#E95420` (Ubuntu orange)
- Font: UbuntuMono Nerd Font / FiraCode Nerd Font
