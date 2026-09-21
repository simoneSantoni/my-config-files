# Emacs

GNU Emacs configuration for research computing and writing: LSP-backed Python,
Julia, R, and TeX editing, Quarto/Markdown authoring, org-roam notes with an
agenda-integrated calendar, mail (mu4e), Zulip chat, Git (magit), PDF viewing,
an in-editor terminal, Spotify control, and Claude Code / Codex integration.
Single-file config (`init.el`) using the built-in `package.el` with GNU/NonGNU
ELPA + MELPA archives plus `package-vc-install` for Git-only packages.

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

`init.el` is self-bootstrapping: on first launch it refreshes the package
archives and installs every missing package itself — archive packages from the
`required-packages` list, Git-only packages via `package-vc-install`. No manual
`package-install` step is needed.

## Emacs packages

Installed from ELPA/MELPA (the `required-packages` list in `init.el`):

**Minibuffer & completion**

| Package | Purpose |
|---------|---------|
| `vertico` | Vertical minibuffer completion UI |
| `orderless` | Space-separated, any-order matching for all completion |
| `marginalia` | Annotations (docstrings, file sizes, …) in the minibuffer |
| `consult` | Enhanced search/navigation commands (`M-s l` line search, `consult-xref`, …) |
| `embark` / `embark-consult` | Act on the thing at point / minibuffer candidate |
| `corfu` | In-buffer completion popup — the single completion UI for both LSP clients |
| `cape` | Extra completion-at-point backends (files, dabbrev, …) |

**Languages & IDE**

| Package | Purpose |
|---------|---------|
| `lsp-mode` | LSP client for Python (pylsp), Julia (JETLS), and R (languageserver) |
| `eldoc-box` | Floating childframe for eldoc/LSP documentation |
| `ess` | R editing and console (Emacs Speaks Statistics) |
| `julia-mode` | Julia major mode |
| `reformatter` | Defines `air-format-on-save-mode` for R formatting |
| `quarto-mode` | `.qmd` authoring (autoloads only) |
| `markdown-mode` / `markdown-toc` | Markdown editing / table-of-contents generation |
| `csv-mode` | CSV/TSV editing |
| `rainbow-delimiters` | Rainbow parens in programming modes |

(TeX uses the *built-in* eglot with digestif — two LSP clients coexist on
disjoint major modes by design.)

**Org & notes**

| Package | Purpose |
|---------|---------|
| `org-roam` | Zettelkasten over `~/org-mode`; `C-c n` prefix |
| `org-roam-protocol` | Bundled module for Org-roam capture through Org protocol links |
| `org-roam-graph` | Bundled static graph generator; requires Graphviz's `dot` executable |
| `org-roam-dailies` | Bundled daily-note capture and navigation commands |
| `org-roam-export` | Bundled HTML-export support for Org-roam ID links |
| `org-download` | MELPA package for image downloads, drag-and-drop, and screenshots; uses Org attachments |
| `mathpix` | Installed from [upstream Git](https://github.com/jethrokuan/mathpix.el); screenshot-to-LaTeX OCR |
| `sqlite3` | Dynamic SQLite module backing org-roam's database (this Emacs build lacks `--with-sqlite3`) |
| `citar` | Completion UI over `~/org-mode/bibliography.bib`; drives org-cite's insert/follow/activate processors (`C-c C-x @`) |
| `citar-org-roam` | Makes org-roam nodes citar's note store — a reference note is a node with the citekey in `ROAM_REFS` (`C-c n r`) |
| `org-roam-bibtex` | Citekey-keyed capture templates and attachment handling; `orb-insert-link` on `C-c n b` |
| `org-roam-ui` | Node graph served to the browser (`C-c n g`); excluded from deferred native compilation to avoid upstream alias warnings |
| `org-roam-ql` | Query language over the node database (`C-c n q`) |

Use `M-x org-download-yank` for an image URL, `M-x org-download-screenshot`
for a region capture, or `M-x mathpix-screenshot` for equation OCR. Both screenshot
commands use KDE Spectacle when available. Mathpix sends the selected image to its
API; set `MATHPIX_APP_ID` and `MATHPIX_APP_KEY` before starting Emacs, or configure
`mathpix-app-id` and `mathpix-app-key` privately. Credentials are not stored here.

**Git**

| Package | Purpose |
|---------|---------|
| `magit` | Git porcelain (`C-x g`, autoloaded) |
| `diff-hl` | VC diff indicators in the fringe |

**Writing**

| Package | Purpose |
|---------|---------|
| `olivetti` / `writeroom-mode` / `darkroom` | Three takes on distraction-free writing, kept side by side |

**Appearance**

| Package | Purpose |
|---------|---------|
| `doom-modeline` | Compact, informative mode-line (custom `os-emacs-logos` segment) |
| `minions` | Collapse minor-mode lighters into a single menu |
| `nerd-icons` / `all-the-icons` | Icon sets for the mode-line and Dired |
| `ef-themes` | Active theme pack — `ef-elea-light` loads at startup |
| `solarized-theme` / `doom-themes` | Alternative theme packs, installed but not loaded |

**Tools & applications**

| Package | Purpose |
|---------|---------|
| `vterm` | Native terminal emulator (module compiled on first `M-x vterm`) |
| `pdf-tools` | Image-based PDF viewing via `epdfinfo` (built on first PDF open) |
| `casual` | Transient menus for built-in tools (calc, dired, …) |
| `smudge` | Spotify client: playback, search, playlists (`C-c s` prefix; needs own Spotify OAuth app, credentials in `~/.keys/`) |
| `exec-path-from-shell` | Import login-shell `PATH`/env into GUI Emacs (so `~/.local/bin` tools like `claude` are found) |
| `compat` | Compatibility shims; loaded early so `transient` macros (e.g. `static-when`) are defined |

Installed from Git with `package-vc-install` (not on any archive; note the
package is named after the *repository*, so two of them differ from the feature
they provide):

| Package | Purpose |
|---------|---------|
| `claude-code-ide` | Runs the Claude Code CLI in a vterm buffer with IDE integration |
| `emacs-codex-ide` | Codex CLI client (feature: `codex-ide`) |
| `emacs-zulip` | Zulip chat client (feature: `zulip`; reads `~/zuliprc`) |
| `rainbow-csv` | Per-column colors in CSV buffers |
| `dired-sidebar` | Dired-backed file tree; toggle with `C-x C-n` |
| `org-sidebar` | Org task/outline sidebars; toggle with `C-c n s` / `C-c n t` |
| `all-the-icons-dired` | File-type icons in ordinary Dired buffers |

Built-ins doing package-sized jobs: `eglot` (TeX LSP), `which-key`,
`calendar`/`diary` (integrated with the org agenda), `gnus-icalendar` (mail
calendar invites → org), and `mu4e` (installed by the *system* `maildir-utils`
package, not ELPA).

`transient` (pulled in by `claude-code-ide`) and `modus-themes` are also present
as dependencies / alternatives.

`gnu-elpa-keyring-update` is bootstrapped before other packages so GNU ELPA
signature verification continues to work when distribution-provided signing
keys become stale. Verification is relaxed only while installing that official
keyring package, then returns to Emacs's normal policy.

## System dependencies

These are needed by packages that compile native components or shell out:

| Feature | Requires |
|---------|----------|
| `vterm` native module | `cmake`, `libtool`, a C compiler |
| `pdf-tools` (`epdfinfo`) | `poppler` + `glib` development headers, build toolchain |
| `claude-code-ide` / `codex-ide` | `claude` / `codex` CLIs on `PATH` (resolved via `exec-path-from-shell`) |
| `org-roam` (`sqlite3` module) | libsqlite3 development headers (module compiled on first load) |
| TeX LSP (eglot) | `digestif` (ships with TeX Live) |
| Python LSP | `pylsp` from the dedicated `emacs-lsp` conda env |
| Julia LSP | JETLS (`jetls` in `~/.julia/bin`), Julia ≥ 1.12.2 |
| R LSP / formatting | R `languageserver` package / `air` in `~/.local/bin` |
| Quarto render/preview | `quarto` CLI (editing `.qmd` works without it) |
| `smudge` (Spotify) | Own Spotify OAuth app; client id/secret in `~/.keys/spotify-client-{id,secret}.txt` |
| Mode-line glyphs / default font | **JuliaMono Nerd Font Mono** (also run `M-x nerd-icons-install-fonts`) |

### mu4e mail setup

Fedora provides mu and mu4e in `maildir-utils`. Mail is downloaded by
OfflineIMAP and sent by msmtp:

```bash
sudo dnf install maildir-utils offlineimap msmtp libsecret
ln -sf "$(pwd)/offlineimaprc" ~/.offlineimaprc
ln -sf "$(pwd)/offlineimap.py" ~/.offlineimap.py
ln -sf "$(pwd)/msmtprc" ~/.msmtprc
chmod 0600 ~/.keys/emacs_stellaris16.txt
offlineimap -o
mu index
```

The Gmail App Password is read from `~/.keys/emacs_stellaris16.txt`; that file
must contain only the password and must remain readable only by its owner. The
tracked configuration contains no credential. The same file is used for Gmail
IMAP and SMTP. OfflineIMAP keeps the most recent 30 days of mail. The TLS
trust-store path is Fedora-specific.

## Notable configuration

- **Toolbar** forced to `image` style (this GTK3 build otherwise inherits the
  desktop's `text` toolbar style and shows icon descriptions instead of icons).
- **Theme**: `ef-elea-light` on startup; toggle light/dark with `M-x ef-themes-toggle`.
- **Font**: JuliaMono Nerd Font Mono at height 120 / size 12.
- **Mode-line**: custom `os-emacs-logos` segment (Emacs + Tux glyphs) prepended
  to doom-modeline's default `main` modeline.
