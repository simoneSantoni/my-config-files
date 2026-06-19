# Emacs

GNU Emacs configuration focused on Markdown editing, PDF viewing, an in-editor
terminal, and Claude Code integration. Single-file config (`init.el`) using the
built-in `package.el` with GNU/NonGNU ELPA + MELPA archives.

Tested with **GNU Emacs 30.2** (GTK3/pgtk build).

## Files

- `init.el` — the entire configuration. Loaded from `~/.emacs.d/init.el`.

Everything else under `~/.emacs.d/` (`elpa/`, `eln-cache/`, `auto-save-list/`,
`url/`, claude-code-ide state) is generated at runtime and is **not** tracked.

## Installation

Symlink `init.el` into your Emacs directory:

```bash
ln -sf "$(pwd)/init.el" ~/.emacs.d/init.el
```

On first launch, `init.el` refreshes the package archives if the cache is empty.
Install the packages listed below with `M-x package-install`, or
`package-list-packages`, then restart Emacs.

## Emacs packages

Installed from ELPA/MELPA (required explicitly in `init.el`):

| Package | Purpose |
|---------|---------|
| `exec-path-from-shell` | Import login-shell `PATH`/env into GUI Emacs (so `~/.local/bin` tools like `claude` are found) |
| `compat` | Compatibility shims; loaded early so `transient` macros (e.g. `static-when`) are defined |
| `markdown-mode` | Major mode for `.md` / `.markdown` |
| `markdown-toc` | Generate/refresh a table of contents |
| `vterm` | Native terminal emulator (compiled on first load) |
| `claude-code-ide` | Runs the Claude Code CLI in a vterm buffer with IDE integration |
| `pdf-tools` | Image-based PDF viewing via `epdfinfo` (built on first PDF open) |
| `doom-modeline` | Compact, informative mode-line |
| `minions` | Collapse minor-mode lighters into a single menu |
| `nerd-icons` | Glyph/icon set used by the mode-line |
| `ef-themes` | Legible light/dark themes (`ef-light` loaded by default) |

`transient` (pulled in by `claude-code-ide`) and `modus-themes` are also present
as dependencies / alternatives.

## System dependencies

These are needed by packages that compile native components or shell out:

| Feature | Requires |
|---------|----------|
| `vterm` native module | `cmake`, `libtool`, a C compiler |
| `pdf-tools` (`epdfinfo`) | `poppler` + `glib` development headers, build toolchain |
| `claude-code-ide` | `claude` CLI on `PATH` (resolved via `exec-path-from-shell`) |
| Mode-line glyphs / default font | **JuliaMono Nerd Font Mono** (also run `M-x nerd-icons-install-fonts`) |

## Notable configuration

- **Toolbar** forced to `image` style (this GTK3 build otherwise inherits the
  desktop's `text` toolbar style and shows icon descriptions instead of icons).
- **Theme**: `ef-light` on startup; toggle light/dark with `M-x ef-themes-toggle`.
- **Font**: JuliaMono Nerd Font Mono at height 120 / size 12.
- **Mode-line**: custom `os-emacs-logos` segment (Emacs + Tux glyphs) prepended
  to doom-modeline's default `main` modeline.
