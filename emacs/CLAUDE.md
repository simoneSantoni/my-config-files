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
   misses `~/.local/bin` (the `claude` CLI) and other shell PATH entries.
   `exec-path-from-shell-arguments` is **nil**, not the default
   `("-l" "-i")`: PATH lives in `~/.zshenv` (sourced by every zsh invocation),
   so a bare `zsh -c` sees it without loading `~/.zshrc` — oh-my-zsh, compinit,
   zinit, nvm and fastfetch. That turns a 150ms–1s shell call (which tripped
   exec-path-from-shell's own "execution took … ms" warning past its 500ms
   `exec-path-from-shell-warn-duration-millis`) into ~2ms. If PATH ever moves
   back into `~/.zshrc`, this must go back to `("-l" "-i")`.
5. `compat` **before** anything pulls in `transient` — transient uses macros
   (`static-when`) that ship in compat but not in Emacs 30.x
6. Feature sections

## Deliberately NOT `require`'d at startup

- **pdf-tools** — `(pdf-loader-install)` defers the one-time `epdfinfo` build
  (poppler + glib headers) until the first PDF opens. Adding
  `(require 'pdf-tools)` triggers that build at every startup — don't.
- **vterm** — its module-compile prompt in the minibuffer can abort daemon
  startup; autoloads are enough.
- **ghostel** — same rule as vterm for the same reason: its libghostty-vt
  module is fetched on first `M-x ghostel`, so only the `C-c t` binding is set.
- **treemacs, calfw** — both fully autoloaded. treemacs also reads its
  persisted workspace lazily; calfw's sources are built inside
  `os-calfw-open`, not at load time.
- **magit, zulip, the theme packs (solarized/doom-themes), olivetti /
  writeroom / darkroom** — all autoloaded; only entry-point keybindings are set.

## Architecture notes

- **Two LSP clients coexist on disjoint major modes** — this is intentional:
  - *eglot* (built-in) drives TeX via digestif (`/usr/bin/digestif`, hardcoded
    because desktop-launched Emacs lacks the login PATH).
  - *lsp-mode* drives Python (basedpyright via the `lsp-pyright` package,
    `uv tool install basedpyright`; multi-root disabled so each project's
    server sees only its own venv — delete `.lsp-session-v1` if that ever
    regresses), Julia (JETLS, hand-registered client, `jetls` on PATH via
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
- **Python IDE** = lsp-mode/basedpyright (above) + yasnippet (enabled per
  prog-mode buffer; `lsp-enable-snippet` is t and needs it in *all* LSP
  buffers) + yasnippet-capf (snippets as corfu candidates, python buffers) +
  dap-mode/debugpy for debugging (`dap-python` is required inside the
  python-mode hook, **not** at startup — it drags in treemacs; debugpy must be
  importable by the project interpreter: `uv add --dev debugpy`) + consult-lsp
  (remapped over `lsp-treemacs-errors-list` / `xref-find-apropos`). Projects
  are uv-managed (`.venv/` auto-detected by lsp-pyright); envrc-global-mode at
  the **end** of init.el (deliberate — envrc must hook last) adds buffer-local
  direnv envs, guarded on the `direnv` binary. Modelled on
  blog.serghei.pl/posts/emacs-python-ide/ with company→corfu, pyenv→uv swaps.
- **R IDE** = ESS (editing/console) + lsp-mode (`languageserver`) + Air
  format-on-save (`reformatter`-defined `air-format-on-save-mode`, guarded on
  `executable-find` so machines without Air no-op) + quarto-mode for `.qmd`
  (autoloads only). `ess-use-flymake` is nil — languageserver's lintr would
  otherwise double-report. R is Fedora's rpm; `languageserver` lives in the
  user library, and its `fs` dependency needs `libuv-devel` to build.
- **Julia REPL** = julia-repl (`julia-repl-mode` on `julia-mode-hook`, vterm
  backend) — the send-to-REPL counterpart of ESS for R; JETLS stays the only
  completion/xref source. Chosen over julia-snail, whose session-fed
  completion/xref backends would compete with lsp-mode's.
- **Julia formatting** = Runic, but reached *through* JETLS, not directly:
  JETLS defaults to `formatter = "Runic"` and shells out to the `runic`
  executable, so `before-save-hook` just calls `lsp-format-buffer`. Unlike R's
  Air there is no `reformatter-define` here — that would be a second formatting
  route over the same buffer. Double-guarded on `lsp-feature?` and
  `executable-find` so buffers with no server, and machines without Runic, skip
  formatting instead of failing the save.
- **org-roam** stores notes in `~/org/roam` and needs a SQLite backend. This
  Emacs build lacks `--with-sqlite3`, so EmacSQL falls back to the `sqlite3`
  dynamic module (compiled on first load, needs libsqlite3 dev headers). If
  Emacs is ever rebuilt with `--with-sqlite3`, drop the `sqlite3` package.
- **Bibliography stack** (citar, citar-org-roam, org-roam-bibtex, org-roam-ui,
  org-roam-ql) sits *after* the `~/org-mode/org-config.el` load, and must stay
  there: that file owns the path to `bibliography.bib` (it sets
  `org-cite-global-bibliography`, `bibtex-completion-bibliography`, and
  `citar-bibliography`), and `org-roam-bibtex-mode` parses the `.bib` as it
  turns on. Two non-obvious settings: `orb-roam-ref-format` is forced to
  `org-cite` because ORB otherwise writes org-ref `cite:` syntax into
  `ROAM_REFS`, and `citar-org-roam-mode` — not ORB — is what owns citar's notes
  source (ORB only reaches for the retired `citar-open-note-function`, finds it
  unbound, and skips it, so both modes can be on).
- **org-ref is installed for BibTeX acquisition/cleaning only, not citations.**
  Citations stay org-cite + citar; org-ref's competing `cite:` links must stay
  out of the notes (hence `orb-roam-ref-format` remains `org-cite`). It is left
  autoloaded — every entry point used (`doi-utils-add-bibtex-entry-from-doi`,
  `org-ref-clean-bibtex-entry`, `arxiv-add-bibtex-entry`, `isbn-to-bibtex`, …)
  has an autoload cookie, and `require`-ing it would install its link types and
  pull citeproc/ox-pandoc/request/avy at startup for nothing. Its optional
  `org-ref-helm.el` / `org-ref-ivy.el` fail to byte-compile on install because
  neither UI is present — expected, nothing loads them.
- **Calendar ↔ org agenda**: `~/org-mode/org-config.el` (agenda files,
  capture, refile — lives in the org repo, not here) is loaded at startup
  when present; `C-c a` opens the agenda. A bootstrapped `~/.emacs.d/diary`
  holds nonmarking `os-diary-holiday-entry`/`org-diary` sexps: holidays and
  diary lines appear in the agenda (`org-agenda-include-diary`), `d` in the
  calendar lists a date's org entries, `c` jumps calendar → day's agenda
  (mirror of org's built-in agenda → calendar `c`).
  **Do not put org's own `org-calendar-holiday` in the diary.** Since org 9.7
  it reads `org-agenda-current-date`, which only org-agenda binds; reached from
  the calendar side (`d`, `M-x diary`) that is nil, so `calendar-check-holidays`
  runs the whole holiday list with `displayed-month` nil and *Warnings* fills
  with one "Bad holiday list item" per entry in `calendar-holidays`. Note the
  symptom is silent until `org-agenda` is loaded — before that the variable is
  merely void and the error is swallowed. `os-diary-holiday-entry` (init.el)
  takes `org-agenda-current-date` **or** diary-lib's `date`, both via `boundp`
  because neither symbol is globally special.
- **calfw** is a *second* calendar, not a replacement: `calendar` keeps the
  diary, holidays and date arithmetic (and its keymap), calfw gives the month
  grid with entry text in the cells. `C-c v` (`os-calfw-open`) merges the
  org-agenda and diary sources into one buffer; `calfw-org-open-calendar` /
  `calfw-cal-open-diary-calendar` remain for single-source views. Uses the
  calfw 2.0 `calfw-` names — pre-2.0 recipes with the `cfw:` prefix need
  `calfw-compat`, which is not loaded. calfw cannot be exercised in
  `--batch`: it blends colours against `(face-foreground/background 'default)`,
  which are `unspecified-fg`/`unspecified-bg` with no frame, and dies in
  `color-rgb-to-hex`. That failure is batch-only — check it in a real frame.
- **Two file trees, deliberately**: dired-sidebar (`C-x C-n`) is a Dired
  buffer, one directory at a time, with nerd-icons wiring; treemacs
  (`C-x t …`) is the persistent multi-project workspace with its own state
  file and git decoration, and does its own icons. treemacs was already on
  disk as a dap-mode dependency (dap-mode's UI is built on it) — it is now
  named in `required-packages` so it is owned rather than inherited.
  `treemacs-git-mode` is `simple`, the pure-Elisp mode, so a machine without
  Python 3 on PATH degrades instead of erroring; `deferred` needs Python 3.
- **Two terminals, deliberately**: vterm (libvterm) stays because
  claude-code-ide and julia-repl are built on it; ghostel (`C-c t`) wraps
  libghostty-vt for what libvterm cannot do — Kitty keyboard/graphics
  protocols, synchronized output, OSC 8 hyperlinks, desktop notifications.
  ghostel needs no build toolchain: the module is a prebuilt download.
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
- **Themes**: three packs installed, one theme active — `ef-elea-light`, loaded
  in the themes section, which is the *only* place the active theme is set.
  `custom-enabled-themes` was deleted from the trailing Custom block on purpose:
  that block runs last and its setter disables every other theme, so a value
  there silently reverted the `load-theme` above it. If Custom writes it back,
  delete it again. `ef-themes-to-toggle` holds the `ef-elea-light`/`-dark` pair.
  Themes stack rather than replace — `disable-theme` before `load-theme`.
- **ef-themes org styling** (themes section, modelled on leuven): scaled title
  (1.6) and headings, overline rules on levels 1–2, blue band on level 1, plus
  a red band on the `:PROPERTIES:` drawer and a purple one on the `#+title:`
  header lines. Three mechanisms, in ascending order of how much they can break:
  - `ef-themes-headings` and `ef-themes-common-palette-overrides` — *not* ef
    variables: since ef-themes 2.0 the pack derives from modus-themes and
    aliases them onto `modus-themes-*`, so they reach every ef theme without
    editing any `ef-*-theme.el`. Use semantic palette names (`bg-blue-subtle`,
    `blue-cooler`, `border`) in the overrides, never hex — that is what keeps
    one setting correct in all 38 themes, light and dark.
  - `os-ef-themes-org-header-faces` on `enable-theme-functions` — the header
    block's faces are foreground-only in modus, so no palette override reaches
    them. Three traps it avoids: `ef-themes-post-load-hook` only fires from
    ef-themes' own commands (plain `load-theme` skips it);
    `ef-themes-with-colors` `eval`s its body dynamically, so a function's
    lexical args are invisible inside it — use `ef-themes-get-color-value`;
    and `custom-theme-set-faces` alone does **not** apply anything, because
    `enable-theme` recalculates faces from the `theme-settings` snapshot it
    takes *before* running `enable-theme-functions` — hence the explicit
    `custom-theme-recalc-face` sweep. Omitting it fails only on frames that
    already exist, i.e. the whole of a normal GUI session, while any *new*
    frame looks correct — so don't verify theme faces by making a frame to
    inspect; probe the initial frame (`emacs --eval …`, no `--batch`).
    It writes with `custom-theme-set-faces` (attributed to the theme, so
    `disable-theme` reverts) rather than `custom-set-faces` (which would leak
    into whatever theme is loaded next).
  - a `font-lock-add-keywords` rule for `#+filetags:` — org hands only
    title/subtitle/author/email/date to the document faces; everything else,
    including every `#+begin_src`, falls to `org-meta-line`, so banding that
    face is not an option.
  - `org-fontify-whole-heading-line` is t and `:extend t` is on the banded
    faces; without those the rules and bands stop at the end of the text.
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
| ghostel native module | none to build — prebuilt libghostty-vt binary downloaded on first `M-x ghostel`; needs `--with-modules` and network on first run |
| treemacs git decoration | `git`; `treemacs-git-mode` `deferred` additionally needs Python 3 (`simple` is set here and needs neither) |
| pdf-tools (epdfinfo) | poppler + glib dev headers, build toolchain |
| org-roam (sqlite3 module) | libsqlite3 dev headers |
| claude-code-ide / codex-ide | `claude` / `codex` CLIs on PATH |
| TeX LSP | digestif (ships with TeX Live), `/usr/bin/info` + latex2e.info for docs |
| Python LSP | basedpyright: `uv tool install basedpyright` (uv itself: `curl -LsSf https://astral.sh/uv/install.sh \| sh`) |
| Python debugging (dap-mode) | `debugpy` importable by the project interpreter (`uv add --dev debugpy`) |
| Per-project envs (envrc) | `direnv` (`sudo dnf install direnv`); optional — init guards on it |
| Julia LSP | JETLS (`jetls` in `~/.julia/bin`), Julia ≥ 1.12.2 |
| Julia formatting | Runic (`runic` in `~/.julia/bin`, `Pkg.Apps.add("Runic")`); JETLS shells out to it |
| R LSP | R `languageserver` package (needs `libuv-devel` to build its `fs` dep) |
| R formatting | `air` in `~/.local/bin` (posit-dev/air installer script) |
| Quarto render/preview | `quarto` CLI (editing `.qmd` works without it) |
| Mermaid render (mermaid-mode `C-c C-c`) | `mmdc` (`npm install -g @mermaid-js/mermaid-cli`); editing `.mmd` works without it |
| mu4e mail | Fedora `maildir-utils`, offlineimap, msmtp (see README) |
| Spotify (smudge) | own Spotify OAuth app; client id/secret in `~/.keys/spotify-client-{id,secret}.txt` |
| Mode-line icons / font | JuliaMono Nerd Font Mono; `M-x nerd-icons-install-fonts` |
