# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NeoMutt email client configuration for Gmail. NeoMutt is a terminal-based email client.

## Testing Configuration

```bash
# Check configuration syntax (will show errors if any)
neomutt -D

# Launch neomutt (requires password in pass store)
neomutt

# Launch without user config (for debugging)
neomutt -n
```

## File Structure

- `neomuttrc` - Main configuration file (IMAP/SMTP settings, keybindings, UI options)
- `mailcap` - MIME type handlers (HTML via lynx, PDF via firefox)
- `signature` - Email signature
- `colors/` - All color schemes (ubuntu-yaru, solarized, neonwolf, nightvision)

## Key Configuration Details

- **Email provider**: Gmail via IMAPS (port 993) and SMTPS (port 465)
- **Password management**: Uses `pass show email/gmail` for credentials
- **Editor**: nvim
- **Cache locations**: `~/.cache/neomutt/headers` and `~/.cache/neomutt/bodies`
- **Attachments saved to**: `~/Documents/attachments/`
- **HTML rendering**: lynx (auto-view enabled), zathura as secondary
- **Sidebar**: Enabled at 25 columns width

## Gmail Mailboxes

Standard Gmail folders plus custom labels: `admin`, `ba`, `@citystgeorges`, `career`, `community`, `conferences`, `grants`, `IT`, `LBS`, `outreach`, `phdSupervision`, `research`, `review`, `teaching`, `training`, `travels`

## Keybindings

- `j/k` - Navigate entries/lines (vim-style)
- `g/G` - Go to top/bottom
- `Ctrl-D/Ctrl-U` - Page down/up
- `b` - Toggle sidebar visibility
- `Ctrl-k/Ctrl-j` - Navigate sidebar up/down
- `o` - Open selected sidebar folder
- `A` - Mark all new messages as read
- `a` - Group reply
- `Enter` (in attach view) - Open attachment with mailcap handler
- `s` (in attach view) - Save attachment to `~/Documents/attachments/`

## Color Schemes

Currently using **Ubuntu-Yaru** (256-color with `color_directcolor` enabled for hex colors). To change, edit the `source` line in `neomuttrc`:
```
source ~/.config/neomutt/colors/mutt-colors-ubuntu-yaru-256.neomuttrc
```

Available schemes in `colors/`:
- `mutt-colors-ubuntu-yaru-256.neomuttrc` (256-color with hex, based on yaru.nvim)
- `mutt-colors-ubuntu-yaru-truecolor.neomuttrc` (true color version)
- `solarized-dark-256.neomuttrc` (256-color)
- `solarized-dark-16.muttrc` (16-color)
- `mutt-colors-neonwolf-256.muttrc`
- `mutt-colors-nightvision-256.muttrc`

## Dependencies

Requires: `neomutt`, `pass`, `lynx`, `nvim` (see README.md for installation)
