# i3 Configuration

Personal i3 window manager configuration with Polybar, Rofi, and gaps.

## Features

- **Polybar** status bar (i3bar disabled)
- **Rofi** application launcher with custom theme
- **Gaps** (5px inner/outer)
- **Yaru** color scheme (orange accent)
- **GB keyboard** layout

## Key Bindings

| Key | Action |
|-----|--------|
| `Super+Return` | Kitty terminal |
| `Super+x` | Rofi launcher |
| `Super+d` | dmenu |
| `Super+Shift+q` | Kill window |
| `Super+r` | Resize mode |
| `Super+p` | Toggle polybar |
| `Super+F1` | Mute |
| `Super+F2/F3` | Volume -/+ |
| `Super+F4` | Mic mute |
| `Super+F5/F6` | Brightness -/+ |
| `Super+Shift+c` | Reload config |
| `Super+Shift+r` | Restart i3 |

## Dependencies

- [polybar](https://github.com/polybar/polybar)
- [rofi](https://github.com/davatorium/rofi)
- [kitty](https://sw.kovidgoyal.net/kitty/)
- [feh](https://feh.finalrewind.org/)
- brightnessctl
- pactl (PulseAudio)
- dex, xss-lock, nm-applet

## Files

- `config` - Main configuration
