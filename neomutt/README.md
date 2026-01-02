# NeoMutt Configuration for Gmail

Terminal-based email client configuration using NeoMutt with Gmail IMAP/SMTP.

## Prerequisites

- [NeoMutt](https://neomutt.org/) installed
- [pass](https://www.passwordstore.org/) (password manager) with Gmail credentials stored at `email/gmail`
- [lynx](https://lynx.invisible-island.net/) for HTML email rendering
- [nvim](https://neovim.io/) as the email editor (configurable in `neomuttrc`)

## Setup

### 1. Install dependencies

```bash
# Debian/Ubuntu
sudo apt install neomutt pass lynx neovim

# Arch
sudo pacman -S neomutt pass lynx neovim
```

### 2. Configure password store

```bash
# Initialize pass if not already done
gpg --gen-key
pass init <your-gpg-id>

# Store your Gmail App Password
pass insert email/gmail
```

> **Note**: You must use a [Gmail App Password](https://support.google.com/accounts/answer/185833) if you have 2-Step Verification enabled (recommended).

### 3. Create required directories

```bash
mkdir -p ~/.cache/neomutt/headers ~/.cache/neomutt/bodies
mkdir -p ~/.neomutt
mkdir -p ~/Documents/attachments
```

### 4. Update configuration

Edit `neomuttrc` and replace:
- `set realname = "Your Name"`
- `set from = "your.email@gmail.com"`
- `set imap_user = "your.email@gmail.com"`
- `set smtp_url = "smtps://your.email@gmail.com@smtp.gmail.com:465/"`

Update `signature` with your email signature.

### 5. Verify and launch

```bash
# Check for configuration errors
neomutt -D

# Launch NeoMutt
neomutt
```

## Keybindings

| Key | Context | Action |
|-----|---------|--------|
| `j/k` | index/pager | Navigate down/up |
| `g/G` | index/pager | Go to first/last |
| `Ctrl-D/Ctrl-U` | all | Page down/up |
| `b` | index/pager | Toggle sidebar |
| `Ctrl-k/Ctrl-j` | index/pager | Navigate sidebar up/down |
| `o` | index/pager | Open selected sidebar folder |
| `A` | index | Mark all new as read |
| `a` | index/pager | Group reply |
| `Enter` | attach | Open with mailcap handler |
| `s` | attach | Save to ~/Documents/attachments/ |

## Color Schemes

The default theme is **Ubuntu-Yaru** (based on [yaru.nvim](https://github.com/simoneSantoni/yaru.nvim)).

To change themes, edit the `source` line at the end of `neomuttrc`:

```bash
# Ubuntu-Yaru (default)
source ~/.config/neomutt/colors/mutt-colors-ubuntu-yaru-256.neomuttrc

# Solarized Dark
source ~/.config/neomutt/colors/solarized-dark-256.neomuttrc

# Neonwolf
source ~/.config/neomutt/colors/mutt-colors-neonwolf-256.muttrc

# Nightvision
source ~/.config/neomutt/colors/mutt-colors-nightvision-256.muttrc
```

## File Structure

```
~/.config/neomutt/
├── neomuttrc          # Main configuration
├── mailcap            # MIME type handlers
├── signature          # Email signature
└── colors/            # Color schemes
```

## Troubleshooting

### Connection errors
- Verify your App Password is correct: `pass show email/gmail`
- Check SSL certificates path in `neomuttrc` matches your system

### HTML emails not rendering
- Ensure lynx is installed: `which lynx`
- Check mailcap configuration

### Slow performance
- Headers and bodies are cached in `~/.cache/neomutt/`
- Increase `imap_keepalive` value if connections drop frequently
