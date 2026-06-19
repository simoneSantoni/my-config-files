# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

GNU Emacs 30.2 configuration. A single `init.el` using the built-in `package.el`
(GNU/NonGNU ELPA + MELPA). No use-package, no literate org config — packages are
loaded with plain `require` and configured imperatively.

## Architecture

- `init.el` — the entire configuration, loaded from `~/.emacs.d/init.el`.
- Installed packages live in `~/.emacs.d/elpa/` (generated, not in this repo).

The file is organized as commented sections in load order. **Order matters and
is deliberate:**

1. `tool-bar-style` set before frames render
2. Package archives + `package-initialize`, refreshing archives only if the cache is empty
3. `exec-path-from-shell` — runs only under a window system or daemon; imports the
   login-shell `PATH` so GUI Emacs can find `~/.local/bin` tools (the `claude` CLI)
4. `compat` required **before** anything pulls in `transient` — transient uses
   macros (e.g. `static-when`) that ship in compat but not in Emacs 30.x
5. Feature sections: markdown, vterm, claude-code-ide, pdf-tools, modeline, theme, font

When adding packages, preserve this ordering rationale rather than appending blindly.

## Key Details

- **pdf-tools is intentionally not `require`d.** It uses `(pdf-loader-install)`
  so the one-time `epdfinfo` build (needs poppler + glib headers) is deferred
  until the first PDF is opened. Adding `(require 'pdf-tools)` would trigger that
  build at every startup — don't.
- **vterm** compiles a native module on first load (needs cmake + libtool).
- **doom-modeline custom segment**: `os-emacs-logos` is prepended to a redefined
  `main` modeline. The two segment lists in `doom-modeline-def-modeline` mirror
  doom-modeline's upstream default — if doom-modeline changes its defaults, these
  lists must be re-synced by hand.

## Validation

`init.el` has no test suite. Verify changes load cleanly in batch mode:

```bash
# Loads init.el headlessly and reports key modes; non-zero/errors mean a problem
emacs --batch -l ~/.emacs.d/init.el \
  --eval '(message "INIT OK: doom=%s minions=%s pdf=%s" (bound-and-true-p doom-modeline-mode) (bound-and-true-p minions-mode) (fboundp (quote pdf-view-mode)))'
```

Batch mode skips `exec-path-from-shell` (no window system) and GUI/font setup, so
it validates syntax and package loading, not appearance. For visual changes, open
Emacs and inspect; check `*Messages*` and `M-x package-list-packages` for errors.

## System Dependencies

| Feature | Dependencies |
|---------|-------------|
| vterm native module | cmake, libtool, C compiler |
| pdf-tools (epdfinfo) | poppler + glib dev headers, build toolchain |
| claude-code-ide | `claude` CLI on PATH |
| Mode-line icons / font | JuliaMono Nerd Font Mono; `M-x nerd-icons-install-fonts` |
