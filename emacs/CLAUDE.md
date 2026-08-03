# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

GNU Emacs 30.2 (GTK3/pgtk, `--with-native-compilation=aot`, `--with-modules`,
**not** `--with-sqlite3`) configuration. A single `init.el` using the built-in
`package.el` (GNU/NonGNU ELPA + MELPA + `package-vc-install` for Git-only
packages). No use-package, no literate org config — packages are loaded with
plain `require` and configured imperatively, with a long comment above each
section explaining *why* it is written that way. Keep that style: when changing
a section, update its comment; when adding one, write the rationale down.

## Deployment

The real file lives in this repo; `~/.emacs.d/init.el` is a symlink to it.
Everything else under `~/.emacs.d/` (`elpa/`, `eln-cache/`, …) is generated.
Edit here, then restart Emacs or `M-x load-file`.

`init.el` is self-bootstrapping: on startup it installs any missing package —
archive packages via the `required-packages` list, Git-only packages via
`package-vc-install` (claude-code-ide, emacs-codex-ide, rainbow-csv,
emacs-zulip, dired-sidebar, org-sidebar, all-the-icons-dired). To add a
package, add it to the right one of those two mechanisms, not just a `require`.

**Gotcha:** `package-vc-install` names the package after the *repository*, so
the codex and zulip packages are `emacs-codex-ide` and `emacs-zulip` even
though their features are `codex-ide` and `zulip`. Guard installs on the
package name or the package reinstalls on every startup.

## Load order (deliberate — don't append blindly)

1. `tool-bar-style` before any frame renders
2. Package archives + keyring bootstrap (`gnu-elpa-keyring-update`, with
   signature checking relaxed only for that one install)
3. Package installation (archive list, then the `package-vc-install` block)
4. `exec-path-from-shell` (window-system/daemon only) — GUI Emacs otherwise
   misses `~/.local/bin` (the `claude` CLI) and other login-shell PATH entries
5. `compat` **before** anything pulls in `transient` — transient uses macros
   (`static-when`) that ship in compat but not in Emacs 30.x
6. Feature sections

## Deliberately NOT `require`'d at startup

- **pdf-tools** — `(pdf-loader-install)` defers the one-time `epdfinfo` build
  (poppler + glib headers) until the first PDF opens. Adding
  `(require 'pdf-tools)` triggers that build at every startup — don't.
- **vterm** — its module-compile prompt in the minibuffer can abort daemon
  startup; autoloads are enough.
- **magit, zulip, the theme packs (solarized/doom-themes), olivetti /
  writeroom / darkroom** — all autoloaded; only entry-point keybindings are set.

## Architecture notes

- **Two LSP clients coexist on disjoint major modes** — this is intentional:
  - *eglot* (built-in) drives TeX via digestif (`/usr/bin/digestif`, hardcoded
    because desktop-launched Emacs lacks the login PATH).
  - *lsp-mode* drives Python (pylsp from the dedicated `emacs-lsp` conda env,
    hardcoded path), Julia (JETLS, hand-registered client, `jetls` on PATH via
    juliaup, needs Julia ≥ 1.12.2), and R (attaches to ESS's `ess-r-mode`).
  - *corfu* is the only completion UI for both (`lsp-completion-provider :none`
    keeps lsp-mode from trying company); eldoc + eldoc-box render docs.
- **Minibuffer stack**: vertico + orderless + marginalia + consult + embark
  (plus cape behind the in-buffer capfs). All ride `completing-read` — no
  helm/ivy. `completion-styles` is `(orderless basic)`, which corfu consults
  too, so LSP completion shares the matching. Conservative bindings: `C-s`
  stays isearch (consult-line is `M-s l`), `C-x C-r` stays recentf-open.
  xref results route through `consult-xref`. which-key is the Emacs 30
  built-in, not the package.
- **R IDE** = ESS (editing/console) + lsp-mode (`languageserver`) + Air
  format-on-save (`reformatter`-defined `air-format-on-save-mode`, guarded on
  `executable-find` so machines without Air no-op) + quarto-mode for `.qmd`
  (autoloads only). `ess-use-flymake` is nil — languageserver's lintr would
  otherwise double-report. R is Fedora's rpm; `languageserver` lives in the
  user library, and its `fs` dependency needs `libuv-devel` to build.
- **org-roam** stores notes in `~/org/roam` and needs a SQLite backend. This
  Emacs build lacks `--with-sqlite3`, so EmacSQL falls back to the `sqlite3`
  dynamic module (compiled on first load, needs libsqlite3 dev headers). If
  Emacs is ever rebuilt with `--with-sqlite3`, drop the `sqlite3` package.
- **mu4e** is optional (`(require 'mu4e nil :noerror)`) — a missing system
  package must never break startup. Mail flow: OfflineIMAP → `~/.maildir` →
  `mu` index → mu4e; sending via msmtp. This repo also holds `offlineimaprc`,
  `offlineimap.py`, `msmtprc` (symlinked to `~/`); credentials live outside the
  repo in `~/.keys/`. Gmail locale is UK English: real trash is
  `[Gmail].Bin`, and the user-created `[Gmail]/Trash` label is a decoy —
  don't "fix" the trash folder. `mu4e-maildir-shortcuts` mirrors the Gmail
  label set; add a line when a label is added.
- **zulip** reads `~/zuliprc` (undotted — where zulip-terminal saves it), and
  carries an advice-based workaround (`zulip--prefer-delivery-email`) for an
  upstream bug on realms that restrict email visibility. Remove it only if
  upstream starts preferring `delivery_email`.
- **smudge** OAuth is advised (`smudge--auth-bounded`): upstream's flow
  blocks Emacs in an unbounded wait for the browser callback and leaves a
  stuck in-progress flag on C-g that re-freezes Emacs from the poll timer.
  The advice adds a 120s timeout and full cleanup. Remove it only if
  upstream bounds the wait and clears the flag itself.
- **doom-modeline custom segment**: `os-emacs-logos` is prepended to a
  redefined `main` modeline. The two segment lists in
  `doom-modeline-def-modeline` mirror doom-modeline's upstream default — if
  doom-modeline updates its defaults, re-sync those lists by hand.
- **Themes**: three packs installed, one theme active (`ef-elea-light`).
  Themes stack rather than replace — `disable-theme` before `load-theme`.
- The trailing `custom-set-variables` block is owned by Custom (it records
  `package-vc-selected-packages`); leave it as the single instance at the end.

## Validation

`init.el` has no test suite. Verify changes load cleanly in batch mode:

```bash
emacs --batch -l ~/.emacs.d/init.el \
  --eval '(message "INIT OK: doom=%s corfu=%s roam=%s" (bound-and-true-p doom-modeline-mode) (bound-and-true-p global-corfu-mode) (featurep (quote org-roam)))'
```

Batch mode skips `exec-path-from-shell`, GUI/font setup, and the
`display-graphic-p`-guarded pieces, so it validates syntax and package loading,
not appearance. For visual changes, open Emacs and check `*Messages*`.
Native-comp warnings are logged to `*Native-compile-Log*` (report style is
`silent` — deliberate; see the comment at the top of `init.el`).

## System Dependencies

| Feature | Dependencies |
|---------|-------------|
| vterm native module | cmake, libtool, C compiler |
| pdf-tools (epdfinfo) | poppler + glib dev headers, build toolchain |
| org-roam (sqlite3 module) | libsqlite3 dev headers |
| claude-code-ide / codex-ide | `claude` / `codex` CLIs on PATH |
| TeX LSP | digestif (ships with TeX Live), `/usr/bin/info` + latex2e.info for docs |
| Python LSP | `conda create -n emacs-lsp -c conda-forge python-lsp-server` |
| Julia LSP | JETLS (`jetls` in `~/.julia/bin`), Julia ≥ 1.12.2 |
| R LSP | R `languageserver` package (needs `libuv-devel` to build its `fs` dep) |
| R formatting | `air` in `~/.local/bin` (posit-dev/air installer script) |
| Quarto render/preview | `quarto` CLI (editing `.qmd` works without it) |
| mu4e mail | Fedora `maildir-utils`, offlineimap, msmtp (see README) |
| Spotify (smudge) | own Spotify OAuth app; client id/secret in `~/.keys/spotify-client-{id,secret}.txt` |
| Mode-line icons / font | JuliaMono Nerd Font Mono; `M-x nerd-icons-install-fonts` |
