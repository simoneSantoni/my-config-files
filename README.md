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
├── emacs/             GNU Emacs configuration
│   └── init.el        Single-file config (package.el + MELPA)
└── zsh/
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

### Emacs (`emacs/`)

GNU Emacs 30 configuration (single `init.el`, package.el + MELPA) for Markdown,
PDF viewing, an in-editor terminal, and Claude Code integration. See
[`emacs/README.md`](emacs/README.md) for the full package list and dependencies.

- **Packages**: markdown-mode, markdown-toc, vterm, claude-code-ide, pdf-tools, doom-modeline, minions, nerd-icons, ef-themes, exec-path-from-shell
- **Theme**: ef-themes (`ef-light` default), JuliaMono Nerd Font Mono
- **Build deps**: cmake + libtool (vterm), poppler + glib headers (pdf-tools)

### ZSH (`.zshrc`)

Shell configuration with Oh-My-Zsh and Zinit.

- **Theme**: robbyrussell
- **Plugins**: git, zsh-syntax-highlighting, zsh-autosuggestions, zsh-history-substring-search, zsh-completions
- **Aliases**: `vim`/`vi` -> nvim, `neomutt` -> launches with `TERM=xterm-direct`
- **Toolchains**: conda (Python/R), juliaup (Julia), nvm (Node.js)
- **Extra paths**: Thunderbird, Zotero, Neovim, R, Spyder

## Installation

Symlink each config directory to `~/.config/`, the shell config to `~/`, and the
Emacs config into `~/.emacs.d/`:

```bash
for dir in nvim neomutt neovide fastfetch; do
  ln -sf "$(pwd)/$dir" ~/.config/"$dir"
done
ln -sf "$(pwd)/zsh/.zshrc" ~/.zshrc
ln -sf "$(pwd)/emacs/init.el" ~/.emacs.d/init.el
```

## Theme

All applications use the **Ubuntu Yaru** color scheme:

| Element    | Value                          |
|------------|--------------------------------|
| Background | `#2C001E` / `#300a24`          |
| Foreground | `#F6F5F4` / `#eeeeec`          |
| Accent     | `#E95420` (Ubuntu orange)      |
| Font       | UbuntuMono / FiraCode Nerd Font |

## Dependencies

**Core**: Neovim 0.10+, NeoMutt, Neovide, Fastfetch, GNU Emacs 30+, Oh-My-Zsh, Zinit

**Fonts**: UbuntuMono Nerd Font, UbuntuSans Nerd Font, FiraCode Nerd Font, JuliaMono Nerd Font

**Neovim tooling**: stylua, black, isort, prettier, texlive, zathura, xdotool, ImageMagick, Zotero (Better BibTeX)

**NeoMutt tooling**: pass, lynx

**Emacs tooling**: cmake, libtool (vterm); poppler + glib dev headers (pdf-tools); `claude` CLI (claude-code-ide)

**Language runtimes**: Python (conda), R (conda), Julia (juliaup), Node.js (nvm)

## License

[MIT](LICENSE) - Simone Santoni, 2024
