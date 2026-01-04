# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an i3 window manager configuration directory. The main configuration is in `config`, with `config.bak` as a backup.

## Applying Changes

After editing `config`, reload i3:
- `$mod+Shift+c` - reload configuration (from within i3)
- `$mod+Shift+r` - restart i3 in-place (preserves session)
- Or run: `i3-msg reload`

## Configuration Structure

The config uses i3 v4 syntax. Key sections:

- **Modifier key**: `$mod` is set to Mod4 (Super/Windows key)
- **Keyboard**: GB layout via `setxkbmap`
- **Terminal**: Kitty at `/home/simon/.local/kitty.app/bin/kitty`
- **Launcher**: Rofi (`$mod+x`) and dmenu (`$mod+d`)
- **Bar**: Polybar (i3bar is commented out)
- **Gaps**: 5px inner and outer gaps enabled
- **Theme**: Yaru color scheme (alternatives commented: Nightvision)

## Key Bindings Reference

| Binding | Action |
|---------|--------|
| `$mod+Return` | Terminal |
| `$mod+x` | Rofi launcher |
| `$mod+d` | dmenu launcher |
| `$mod+Shift+q` | Kill window |
| `$mod+r` | Enter resize mode |
| `$mod+p` | Toggle polybar |
| `$mod+F1` | Mute toggle |
| `$mod+F2/F3` | Volume down/up |
| `$mod+F4` | Mic mute toggle |
| `$mod+F5/F6` | Brightness down/up |

## External Dependencies

- `polybar` - status bar (launch script at `~/.config/polybar/launch.sh`)
- `rofi` - application launcher (config at `~/.config/rofi/`)
- `feh` - wallpaper
- `brightnessctl` - screen brightness
- `pactl` - PulseAudio volume control
- `kitty` - terminal emulator
- `dex` - XDG autostart
- `xss-lock` - screen locker
- `nm-applet` - NetworkManager tray
