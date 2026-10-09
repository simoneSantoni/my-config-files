# KDE Plasma

## Besot Haiku window decoration (`aurorae/patch-besot-haiku.py`)

Besot Haiku 3.1 (Aurorae theme by Mark Whittaker, installed under
`~/.local/share/aurorae/themes/besothaiku/`) draws the active titlebar and its
buttons in yellow. The script recolours the theme's SVGs in place:

- **Titlebar**: active uses the same gray gradient as inactive (`#f2f2f2` →
  `#d4d4d4`), matching the window frame of Dolphin.
- **Active buttons** (close, minimize, maximize, restore, keep above/below,
  shade, all desktops — normal, hover, pressed): base fill is `currentColor`
  with class `ColorScheme-ButtonFocus`, which KSvg resolves to the Plasma
  accent colour at runtime; white/black overlays reproduce the original bevel.
  Changing the accent in System Settings recolours the buttons.
- **Inactive buttons**: untouched (gray).

Requires `python3-lxml`.

```bash
kde/aurorae/patch-besot-haiku.py            # default theme dir
kde/aurorae/patch-besot-haiku.py THEME_DIR  # elsewhere
dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure
```

Unpatched `*.svg` files are first saved as `*.svg.orig` and the patch is always
rebuilt from those, so re-running is idempotent. After the theme is upgraded
(store/`Get New…` overwrites the SVGs), just run it again: the fresh files are
detected and snapshotted as the new originals.

Revert to the stock theme:

```bash
cd ~/.local/share/aurorae/themes/besothaiku && for f in *.svg.orig; do cp "$f" "${f%.orig}"; done
```

The yellow → gray titlebar mapping (`DECO_MAP`) and the yellow detection are
tuned to the 3.1 palette; if a future release changes colours, check the result
by rendering, e.g. `rsvg-convert -z 6 close.svg -o close.png` (rsvg draws
`currentColor` as black, since the stylesheet is only filled in by KSvg).
