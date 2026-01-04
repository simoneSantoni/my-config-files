# Rofi Configuration

Application launcher and dmenu replacement.

## Theme

Uses Yaru color scheme via `colors/yaru.rasi`.

## Modes

- `drun` - Application launcher
- `run` - Command runner
- `filebrowser` - File browser
- `window` - Window switcher

## Settings

| Setting | Value |
|---------|-------|
| Font | FiraCode Nerd Font Mono 12 |
| Icon theme | Papirus |
| Case sensitive | No |
| Show icons | Yes |

## Structure

```
rofi/
├── config.rasi        # Main configuration
├── colors/            # Color themes (yaru.rasi active)
├── launchers/         # Launcher styles (type-1 through type-7)
├── powermenu/         # Power menu styles (type-1 through type-6)
├── applets/           # System applets
├── images/            # Background images
└── scripts/           # Launcher scripts
```

## Launcher Scripts

Launch specific styles via `scripts/`:
```bash
./scripts/launcher_t1   # Type 1 launcher
./scripts/powermenu_t1  # Type 1 power menu
```

## Source

Based on [adi1090x/rofi](https://github.com/adi1090x/rofi) configuration.
