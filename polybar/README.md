# Polybar Configuration

Personal polybar status bar configuration for i3 window manager on X11.

## Requirements

- polybar
- i3 window manager
- xrandr
- xkb-switch (or setxkbmap)
- brightnessctl (or xbacklight)
- pactl (PulseAudio)
- Nerd Font (UbuntuSans Nerd Font)

## Usage

```bash
# Start polybar on all connected monitors
./launch.sh
```

Polybar launches automatically with i3 via `exec_always` in the i3 config.

## Modules

| Module | Description | Interaction |
|--------|-------------|-------------|
| xworkspaces | i3 workspace indicators | Click to switch |
| keyboard | Keyboard layout (GB/US) | Click to cycle |
| caffeine | Screen sleep prevention | Click to toggle |
| theme | Light/dark theme | Click to toggle |
| lxappearance | GTK appearance settings | Click to open |
| brightness | Screen brightness | Scroll to adjust |
| layout-extended | Both displays extended | Click to activate |
| layout-external | External display only | Click to activate |
| pulseaudio | Volume control | Click to mute, scroll to adjust |
| memory | RAM usage | - |
| cpu | CPU usage | - |
| battery | Battery status | - |
| wlan | WiFi status and IP | - |
| eth | Ethernet status and IP | - |
| date | Date and time | - |

## Scripts

Located in `scripts/`:

| Script | Purpose |
|--------|---------|
| keyboard-layout.sh | Cycle between GB/US layouts |
| caffeine.sh | Toggle screen sleep prevention |
| theme-toggle.sh | Switch light/dark polybar theme |
| brightness.sh | Adjust screen brightness |
| screen-layout.sh | Cycle multi-monitor layouts |
| monitor-toggle.sh | Toggle individual monitors |

## Theming

Active theme: **Yaru refined** (Ubuntu-inspired)

Alternative themes available in `config.ini` `[colors]` section:
- moonfly
- nightvision
- cyberdream
- material

Toggle between light/dark with the theme module or:

```bash
./scripts/theme-toggle.sh --toggle
```

## Multi-Monitor

Supports laptop (eDP) + external (DisplayPort-1) setup.

Screen layout modes:
- **extend-right** - Side by side, external on right
- **extend-left** - Side by side, external on left
- **mirror** - Same display on both
- **external-only** - Laptop display off
- **laptop-only** - External display off

## i3 Keybindings

| Key | Action |
|-----|--------|
| $mod+F1 | Mute toggle |
| $mod+F2 | Volume -10% |
| $mod+F3 | Volume +10% |
| $mod+F4 | Mic mute toggle |
| $mod+F5 | Brightness -10% |
| $mod+F6 | Brightness +10% |
| $mod+p | Toggle polybar visibility |
