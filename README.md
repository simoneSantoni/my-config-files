# My Configuration Files

Dotfiles for a Linux desktop environment running i3 window manager with Ubuntu Yaru theming.

## Repository Structure

```
.
├── nvim/              Neovim (LazyVim) configuration
│   ├── init.lua
│   ├── lazyvim.json
│   ├── lua/config/    Core settings, keymaps, autocmds
│   └── lua/plugins/   26 plugin specs (Quarto, R, LaTeX, AI, ...)
├── neomutt/           Terminal email client (Gmail)
│   ├── neomuttrc      Main configuration
│   ├── mailcap        MIME type handlers
│   ├── signature      Email signature
│   └── colors/        10 color schemes (ubuntu-yaru, solarized, ...)
├── neovide/           Neovim GUI frontend
│   ├── config.toml
│   └── neovide.desktop
├── fastfetch/         System info display
│   └── config.jsonc
├── ghostty/           Ghostty terminal emulator
│   ├── config.ghostty
│   └── themes/        Custom themes (ef-elea-light)
├── mc/                Midnight Commander configuration
│   └── skins/         True-colour skins
├── emacs/             GNU Emacs configuration
│   └── init.el        Single-file config (package.el + MELPA)
├── hhkb/              HHKB Studio keyboard keymap profiles
│   ├── current-profile-{0..3}.toml   Live profile dumps
│   ├── profile-backup.toml           Factory/known-good restore point
│   └── profile-{0..3}-decoded.txt    Human-readable layout renders
└── zsh/
    ├── .zshenv        PATH only — sourced by every zsh invocation
    └── .zshrc         ZSH shell configuration
```

## Components

### Neovim (`nvim/`)

[LazyVim](https://github.com/LazyVim/LazyVim)-based configuration optimized for scientific writing and data analysis.

- **Language support**: Python, R, Julia, SQL, LaTeX, Quarto, Markdown, JSON, YAML
- **REPL workflow**: vim-slime sends code to terminal; `<C-,><C-,>` sends paragraph, `<C-.><C-.>` sends line
- **Quarto/R**: quarto-nvim, otter.nvim for embedded language support, cmp-r completions
- **Citations**: Zotero integration via telescope-zotero and cmp_zotcite
- **AI assistants**: Claude, Gemini, CodeCompanion plugins
- **Colorscheme**: [yaru](https://github.com/simoneSantoni/yaru.nvim) (Ubuntu Yaru port)

### NeoMutt (`neomutt/`)

Terminal email client configured for Gmail via IMAPS/SMTPS. See [`neomutt/README.md`](neomutt/README.md) for setup instructions.

- **Authentication**: `pass` password manager for credentials
- **Vim-style navigation**: j/k, g/G, Ctrl-D/Ctrl-U, sidebar toggle with `b`
- **HTML rendering**: lynx auto-view
- **Color scheme**: Ubuntu Yaru (256-color with hex via `color_directcolor`)

### Neovide (`neovide/`)

GUI frontend for Neovim. FiraCode Nerd Font Mono at 8pt, maximized on startup, auto theme.

### Fastfetch (`fastfetch/`)

System information display run on shell startup via `.zshrc`. Shows OS, kernel, CPU, GPU, memory, disk, local IP, and color palette.

### Midnight Commander (`mc/`)

True-colour `ef-elea-light` skin matching the Emacs theme. See
[`mc/README.md`](mc/README.md) for requirements, preview, and activation.

### Emacs (`emacs/`)

GNU Emacs 30 configuration (single `init.el`, package.el + MELPA) for Markdown,
PDF viewing, an in-editor terminal, and Claude Code integration. See
[`emacs/README.md`](emacs/README.md) for the full package list and dependencies.

- **Packages**: markdown-mode, markdown-toc, vterm, claude-code-ide, pdf-tools, doom-modeline, minions, nerd-icons, ef-themes, exec-path-from-shell
- **Theme**: ef-themes (`ef-light` default), JuliaMono Nerd Font Mono
- **Build deps**: cmake + libtool (vterm), poppler + glib headers (pdf-tools)

### Ghostty (`ghostty/`)

GPU-accelerated terminal emulator (Fedora: `dnf copr enable scottames/ghostty`).
The whole directory is symlinked to `~/.config/ghostty`, because Ghostty resolves
custom themes from a `themes/` directory beside the config file.

- **Theme**: `ef-elea-light`, a port of the Emacs ef-themes palette to Ghostty's
  16 ANSI slots (`themes/ef-elea-light`) — same palette as `mc/skins/ef-elea-light.ini`
- **Font**: JuliaMono Nerd Font Mono 13pt, matching `emacs/init.el`
- **Reload**: `<C-S-,>` in a running Ghostty; `ghostty +validate-config` to check syntax

### HHKB Studio (`hhkb/`)

Keymap profiles for an HHKB Studio (PD-ID100B, US) managed with
[`hhkb-studio-tools`](https://github.com/yuja/hhkb-studio-tools). The keyboard is the
source of truth; this dir is a versioned snapshot + restore point (no symlink/deploy).
See [`hhkb/README.md`](hhkb/README.md) for the full reference and
[`hhkb/CLAUDE.md`](hhkb/CLAUDE.md) for the gotchas.

- **Customizations** (profile 0 vs factory): Delete→Backspace (Delete on Fn), Left ◇→Fn1, and ◇/Meta placed next to the right of space (Alt moved outboard)
- **Editing requires USB**, not Bluetooth — switch to wired with **Fn+Control+0**; the config interface is the `0xFF60` vendor hidraw, found by probing with `hhkb-studio-tools info`
- **Restore factory**: `hhkb-studio-tools write-profile --device $DEV --index 0 -i hhkb/profile-backup.toml`

### ZSH (`.zshenv`, `.zshrc`)

Shell configuration with Oh-My-Zsh and Zinit.

`.zshenv` holds nothing but PATH. Zsh sources it on *every* invocation —
including a bare `zsh -c` — so Emacs' `exec-path-from-shell` can read the full
PATH without paying for `.zshrc` (Oh-My-Zsh, compinit, Zinit, nvm, fastfetch);
that is why `exec-path-from-shell-arguments` is nil in `emacs/init.el`. Keep
PATH there and everything else in `.zshrc`.

- **Theme**: robbyrussell
- **Plugins**: git, zsh-syntax-highlighting, zsh-autosuggestions, zsh-history-substring-search, zsh-completions
- **Aliases**: `vim`/`vi` -> nvim, `neomutt` -> launches with `TERM=xterm-direct`
- **Toolchains**: conda (Python/R), juliaup (Julia), nvm (Node.js)
- **Extra paths**: Thunderbird, Zotero, Neovim, R, Spyder

## Installation

Run the idempotent linker to connect the standard application config paths to
this checkout. Existing files are moved to a timestamped directory under
`~/.local/state/my-config-files/backups/` before links are created:

```bash
./scripts/link-configs.sh
```

The script links Neovim, NeoMutt, Neovide, Fastfetch, and Ghostty under `~/.config/`,
the Midnight Commander skin under `~/.local/share/mc/skins/`, `zsh/.zshenv`
and `zsh/.zshrc` as `~/.zshenv` and `~/.zshrc`, and only `emacs/init.el` inside `~/.emacs.d/` so Emacs can keep
generated packages and caches alongside it.

## Theme

Two color schemes are in use, split by application:

**Ubuntu Yaru** (dark) — Neovim, NeoMutt, Neovide:

| Element    | Value                          |
|------------|--------------------------------|
| Background | `#2C001E` / `#300a24`          |
| Foreground | `#F6F5F4` / `#eeeeec`          |
| Accent     | `#E95420` (Ubuntu orange)      |
| Font       | UbuntuMono / FiraCode Nerd Font |

**ef-elea-light** (light) — Emacs, Midnight Commander, Ghostty:

| Element    | Value                          |
|------------|--------------------------------|
| Background | `#edf5e2` (bg-main)            |
| Foreground | `#221321` (fg-main)            |
| Accent     | `#770080` (cursor magenta)     |
| Font       | JuliaMono Nerd Font Mono       |

Ported from [ef-themes](https://github.com/protesilaos/ef-themes) 2.2.0. When
changing one of the three, keep `mc/skins/ef-elea-light.ini` and
`ghostty/themes/ef-elea-light` in sync — both derive from the same palette.

## Dependencies

**Core**: Neovim 0.10+, NeoMutt, Neovide, Fastfetch, Ghostty 1.3+, GNU Emacs 30+, Oh-My-Zsh, Zinit

**Fonts**: UbuntuMono Nerd Font, UbuntuSans Nerd Font, FiraCode Nerd Font, JuliaMono Nerd Font

**Neovim tooling**: stylua, black, isort, prettier, texlive, zathura, xdotool, ImageMagick, Zotero (Better BibTeX)

**NeoMutt tooling**: pass, lynx

**Emacs tooling**: cmake, libtool (vterm); poppler + glib dev headers (pdf-tools); `claude` CLI (claude-code-ide)

**Language runtimes**: Python (conda), R (conda), Julia (juliaup), Node.js (nvm)

## License

[MIT](LICENSE) - Simone Santoni, 2024
