# My Configuration Files

Dotfiles for my Linux desktop environment running i3 window manager with Ubuntu Yaru theming.

## Components

| Directory | Application | Purpose |
|-----------|-------------|---------|
| `nvim/` | Neovim | LazyVim-based config for scientific writing (Quarto, R, Python, Julia) |
| `kitty/` | Kitty | Terminal emulator |
| `i3/` | i3wm | Tiling window manager |
| `polybar/` | Polybar | Status bar with custom modules |
| `rofi/` | Rofi | Application launcher |
| `dunst/` | Dunst | Notification daemon |
| `neomutt/` | NeoMutt | Terminal email client (Gmail) |
| `zathura/` | Zathura | PDF viewer |
| `neovide/` | Neovide | Neovim GUI |
| `fastfetch/` | Fastfetch | System info display |
| `.zshrc` | ZSH | Shell configuration (Oh-My-Zsh + Zinit) |

## Installation

Symlink configs to their target locations:

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

## Theme

All applications use the **Ubuntu Yaru** color scheme:
- Background: `#2C001E` / `#300a24`
- Foreground: `#F6F5F4` / `#eeeeec`
- Accent: `#E95420` (Ubuntu orange)
- Font: UbuntuMono Nerd Font / FiraCode Nerd Font

## Dependencies

Core:
- i3-gaps, polybar, rofi, dunst, kitty
- Neovim 0.10+
- Oh-My-Zsh, Zinit

Fonts:
- UbuntuMono Nerd Font
- UbuntuSans Nerd Font
- FiraCode Nerd Font

Utilities:
- brightnessctl, pactl, xrandr, feh
- pass (password manager for neomutt)
- lynx (HTML email rendering)
