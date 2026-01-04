# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal polybar status bar configuration for i3 window manager on X11. Multi-monitor setup with laptop display (eDP) and external monitor (DisplayPort-1).

## Common Commands

```bash
# Restart polybar (kills existing instances and launches on all monitors)
./launch.sh

# Restart via IPC (faster, if polybar already running)
polybar-msg cmd restart

# Test a script directly
./scripts/caffeine.sh --toggle
./scripts/theme-toggle.sh --toggle
./scripts/keyboard-layout.sh --cycle
./scripts/brightness.sh --up
./scripts/screen-layout.sh --cycle
./scripts/screen-layout.sh --set external-only
./scripts/monitor-toggle.sh --toggle eDP
```

Polybar launches automatically via `exec_always` in the i3 config.

## Architecture

- **config.ini** - Main polybar configuration with bar settings, module definitions, and color theme
- **launch.sh** - Startup script that launches polybar on all connected monitors via xrandr
- **scripts/** - Custom bash scripts for interactive modules

### Module Script Pattern

All scripts in `scripts/` follow a consistent pattern:
- Default invocation (no args) returns current status for polybar display
- `--toggle` or `--cycle` for click actions
- State persisted in `/tmp/` files (e.g., `/tmp/caffeine_enabled`, `/tmp/polybar_theme`, `/tmp/screen_layout`)
- Colors use polybar format strings: `%{F#color}text%{F-}`
- Bar is positioned at bottom of screen (`bottom = true`)

### Monitor Names (hardcoded)

Scripts use these xrandr output names:
- `eDP` - Laptop display (primary)
- `DisplayPort-1` - External monitor

### Color Theming

Active theme is "Yaru refined" (Ubuntu-inspired). Multiple commented-out themes available in `[colors]` section: moonfly, nightvision, cyberdream, material.

Theme toggle script (`scripts/theme-toggle.sh`) modifies config.ini in-place with sed, then restarts polybar.

## Dependencies

- polybar, i3, xrandr, xkb-switch (or setxkbmap), brightnessctl (or xbacklight), xset, pactl
- Nerd Font (UbuntuSans Nerd Font configured)

## Key Files

| File | Purpose |
|------|---------|
| config.ini | Bar layout, modules, colors |
| launch.sh | Multi-monitor startup script |
| scripts/caffeine.sh | Prevent screen sleep toggle |
| scripts/theme-toggle.sh | Light/dark theme switcher |
| scripts/keyboard-layout.sh | GB/US keyboard layout cycling |
| scripts/brightness.sh | Screen brightness control |
| scripts/screen-layout.sh | Multi-monitor layout cycling (extend-right, extend-left, mirror, external-only, laptop-only) |
| scripts/monitor-toggle.sh | Individual monitor on/off toggle |

## Logs

Polybar logs to `~/.cache/polybar.log`
