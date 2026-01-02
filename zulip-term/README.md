# Zulip Terminal Configuration

Configuration files for [zulip-term](https://github.com/zulip/zulip-terminal), a terminal client for Zulip chat.

## Files

```
zulip-term/
├── zuliprc.template      # Main config file template
├── themes/
│   ├── ubuntu_yaru_dark.py   # Custom Ubuntu Yaru dark theme
│   └── colors_yaru.py        # Color definitions for Yaru themes
└── README.md
```

## Installation

### 1. Install zulip-term

```bash
# Using conda (recommended)
conda create -n zulip python=3.10
conda activate zulip
pip install zulip-term

# Or using pipx
pipx install zulip-term
```

### 2. Configure zuliprc

Copy the template and fill in your credentials:

```bash
cp zuliprc.template ~/zuliprc
```

Edit `~/zuliprc` and replace:
- `YOUR_EMAIL@example.com` with your Zulip email
- `YOUR_API_KEY` with your API key (get it from Zulip Settings > Personal > API Key)
- `YOUR_ORGANIZATION` with your Zulip organization name

### 3. Install the custom theme

Copy the theme files to your zulip-term installation:

```bash
# Find your zulip-term installation
ZTERM_PATH=$(python -c "import zulipterminal; print(zulipterminal.__path__[0])")

# Copy theme files
cp themes/colors_yaru.py "$ZTERM_PATH/themes/"
cp themes/ubuntu_yaru_dark.py "$ZTERM_PATH/themes/"
```

Then register the theme in `$ZTERM_PATH/config/themes.py`:

```python
# Add to imports
from zulipterminal.themes import ubuntu_yaru_dark

# Add to THEMES dict
THEMES: Dict[str, Any] = {
    # ... existing themes ...
    "ubuntu_yaru_dark": ubuntu_yaru_dark,
}

# Optional: add alias
THEME_ALIASES = {
    # ... existing aliases ...
    "yaru": "ubuntu_yaru_dark",
}
```

## Usage

```bash
# Run with the custom theme
zulip-term -t ubuntu_yaru_dark --color-depth=256

# Or use the alias
zulip-term -t yaru --color-depth=256
```

## Theme: Ubuntu Yaru Dark

A dark theme inspired by Ubuntu's Yaru theme, featuring:

- **Background**: Dark eggplant (`#2C001E`)
- **Selection**: Aubergine (`#924567`) - subtle purple instead of bright orange
- **Accents**: Ubuntu orange (`#E95420`), gold, teal, and green
- **Syntax highlighting**: Monokai-based with Yaru color overrides

### Color Palette

| Color         | Hex       | Usage                    |
|---------------|-----------|--------------------------|
| BG            | `#2C001E` | Main background          |
| FG            | `#F6F5F4` | Primary text             |
| FG_DIM        | `#D5CFCA` | Secondary text           |
| ORANGE        | `#E95420` | Ubuntu accent, keywords  |
| AUBERGINE     | `#772953` | Headers, bars            |
| AUBERGINE_LIGHT | `#924567` | Selection highlight    |
| GOLD          | `#F99B15` | Functions, sender names  |
| GREEN         | `#26A269` | Strings, active users    |
| TEAL          | `#19B6EE` | Links, timestamps        |
| RED           | `#C7162B` | Errors, starred items    |

## Recommended Terminal

For best color rendering, use a terminal that supports 256 colors or true color (24-bit):

- **Kitty** (recommended)
- Alacritty
- GNOME Terminal
- iTerm2 (macOS)

Set your terminal font to a Nerd Font for icon support (e.g., `UbuntuMono Nerd Font`).
