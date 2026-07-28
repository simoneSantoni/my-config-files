;;; init.el --- Personal Emacs configuration  -*- lexical-binding: t; -*-

;; Force the GUI toolbar to show icon images rather than text labels.
;; This GTK3 build otherwise inherits the desktop's
;; org.gnome.desktop.interface toolbar-style ('text'), which made the
;; toolbar render icon descriptions instead of icon pictures.
(setq tool-bar-style 'image)

;; --- Native-compilation warnings --------------------------------------------
;; This build is --with-native-compilation=aot, so every newly installed package
;; is natively compiled in the background and any warning its author left behind
;; pops a *Warnings* buffer in our face. Those warnings are about third-party
;; code we do not maintain, and the ones seen here are false alarms rather than
;; real problems -- typically "the function X is not known to be defined", which
;; the compiler emits whenever a definition is not visible in the single file it
;; is compiling: org-roam's files `require' each other circularly, and its
;; `org-roam-node-slug' calls (require 'ucs-normalize) from inside the function
;; body, so the compiler cannot see either definition even though both resolve
;; fine at runtime.
;;
;; `silent' still records everything in *Native-compile-Log* (`nil' would not),
;; so a genuine failure is still there to read -- it just stops the buffer from
;; stealing the window on every install.
(setq native-comp-async-report-warnings-errors 'silent)

;; Package archives: add MELPA alongside the default GNU/NonGNU ELPA.
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; GNU ELPA rotates its signing keys more often than some Emacs distributions
;; update their bundled keyring. Bootstrap the official keyring updater before
;; installing anything else. Signature checking is disabled only for this
;; catch-22; package.el's normal `allow-unsigned' policy resumes immediately
;; afterward, so signed packages must still have a valid signature.
(unless (package-installed-p 'gnu-elpa-keyring-update)
  (let ((package-check-signature nil))
    (unless package-archive-contents
      (package-refresh-contents))
    (package-install 'gnu-elpa-keyring-update)))

;; On first run (or when the archive cache is empty), refresh package metadata
;; so M-x package-install / package-list-packages can see MELPA packages.
(unless package-archive-contents
  (package-refresh-contents))

;; Ensure every third-party package this init `require's is actually installed.
;; A fresh checkout (or a freshly wiped elpa/) has no packages, so the bare
;; `require' calls below would fail with "Cannot open load file". Install any
;; that are missing, refreshing the archive cache once if a name isn't found.
(let ((required-packages '(exec-path-from-shell
                           compat
                           markdown-mode
                           markdown-toc
                           olivetti
                           writeroom-mode
                           darkroom
                           csv-mode
                           casual
                           vterm
                           pdf-tools
                           doom-modeline
                           minions
                           nerd-icons
                           ef-themes
                           solarized-theme
                           doom-themes
                           magit
                           diff-hl
                           lsp-mode
                           corfu
                           eldoc-box
                           julia-mode
                           ess
                           sqlite3
                           org-roam)))
  (dolist (pkg required-packages)
    (unless (package-installed-p pkg)
      (unless (assq pkg package-archive-contents)
        (package-refresh-contents))
      (package-install pkg))))

;; claude-code-ide isn't published to GNU/NonGNU ELPA or MELPA, so it can't be
;; installed with `package-install'. Pull it straight from its Git repository
;; with `package-vc-install'; that reads its Package-Requires header and pulls
;; the dependencies (websocket, transient, web-server) from the archives.
(unless (package-installed-p 'claude-code-ide)
  (package-vc-install "https://github.com/manzaltu/claude-code-ide.el"))

;; codex-ide (a pure-Emacs Codex client) isn't on any archive either, so pull it
;; from Git the same way; its Package-Requires header names `transient', which
;; resolves from the archives. Note `package-vc-install' names the package after
;; the repository, so the installed package is `emacs-codex-ide' even though the
;; feature it provides is `codex-ide' -- guard on the former or this reinstalls
;; on every startup.
(unless (package-installed-p 'emacs-codex-ide)
  (package-vc-install "https://github.com/dgillis/emacs-codex-ide"))

;; rainbow-csv is published only to the author's JCS-ELPA, not GNU/NonGNU ELPA or
;; MELPA, so `package-install' can't find it. Pull it from Git with
;; `package-vc-install'; its Package-Requires header names `csv-mode', which is
;; already installed above so the dependency resolves from GNU ELPA.
(unless (package-installed-p 'rainbow-csv)
  (package-vc-install "https://github.com/emacs-vs/rainbow-csv"))

;; zulip: a Zulip chat client, not on any archive either. Same repository-name
;; caveat as codex-ide above -- the package is `emacs-zulip' (after the repo) but
;; the feature is `zulip', so guard on `emacs-zulip'. Its Package-Requires names
;; nothing but Emacs 27.1, so there are no dependencies to resolve.
(unless (package-installed-p 'emacs-zulip)
  (package-vc-install "https://github.com/suky57/emacs-zulip"))

;; Import PATH (and other env) from the login shell. GUI Emacs launched from a
;; desktop launcher gets a minimal PATH that omits ~/.local/bin, so tools like
;; the `claude' CLI used by claude-code-ide aren't found. This fixes that.
(require 'exec-path-from-shell)
(when (or (memq window-system '(mac ns x pgtk))
          (daemonp))
  (exec-path-from-shell-initialize))

;; Load compat early. transient (a claude-code-ide dependency) uses macros such
;; as `static-when' that ship in compat but not in Emacs 30.x. Ensuring compat
;; is loaded first guarantees those macros are defined before transient loads.
(require 'compat)

;; --- Markdown ---------------------------------------------------------------
;; markdown-mode: major mode for editing Markdown; use it for .md/.markdown.
(require 'markdown-mode)
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
;; markdown-toc: generate/refresh a table of contents (M-x markdown-toc-generate-toc).
(require 'markdown-toc)

;; --- Notes (org-roam) -------------------------------------------------------
;; Zettelkasten-style linked notes over org-mode. org itself ships with Emacs
;; (9.7.11 here), so only org-roam is installed; there is no org package to add.
;;
;; org-roam keeps a SQLite index of nodes and links, reached through EmacSQL.
;; EmacSQL picks its own backend (see `emacsql-sqlite-default-connection'):
;; built-in SQLite first, else the `sqlite3' dynamic module. This Emacs is built
;; --with-modules but NOT --with-sqlite3, so `sqlite-available-p' is nil and the
;; module is what gets used -- hence `sqlite3' in the package list above. The
;; module is compiled on first load and needs libsqlite3-dev on the system.
;; EmacSQL dropped its old bundled-executable fallback, so without that module
;; org-roam dies at startup with "EmacSQL could not find or compile a back-end".
;; If Emacs is ever rebuilt with --with-sqlite3, the built-in backend wins
;; automatically and `sqlite3' becomes dead weight that can be dropped.
(setq org-roam-directory (expand-file-name "~/org/roam"))
(setq org-roam-db-location (expand-file-name "~/org/roam/org-roam.db"))
;; Suppress the v2 migration prompt: this is a fresh install, not a v1 upgrade.
(setq org-roam-v2-ack t)
;; Show each node's title, then its tags, in the completion list.
(setq org-roam-node-display-template
      (concat "${title:*} " (propertize "${tags:20}" 'face 'org-tag)))
(require 'org-roam)
;; `org-roam-directory' must exist before the database syncs against it.
(make-directory org-roam-directory t)
;; Keep the index live as notes are edited, rather than needing M-x org-roam-db-sync.
(org-roam-db-autosync-mode 1)
;; The `C-c n' prefix is org-roam's own documented convention.
(global-set-key (kbd "C-c n f") #'org-roam-node-find)
(global-set-key (kbd "C-c n i") #'org-roam-node-insert)
(global-set-key (kbd "C-c n c") #'org-roam-capture)
(global-set-key (kbd "C-c n l") #'org-roam-buffer-toggle)

;; --- Distraction-free writing (olivetti / writeroom-mode / darkroom) ---------
;; Three takes on the same idea, kept side by side because they differ in how
;; much they take over:
;;   olivetti-mode  -- margins only: centres the text column in the window and
;;                     leaves everything else (mode-line, other windows) alone.
;;   writeroom-mode -- a global "zen" mode built on visual-fill-column: goes
;;                     fullscreen, hides the mode-line and deletes other windows.
;;   darkroom-mode  -- margins plus a text-scale bump and hidden mode-line;
;;                     `darkroom-tentative-mode' only kicks in when the buffer's
;;                     window is the only one in the frame.
;; All three are autoloaded, so bind entry points rather than `require'-ing them
;; at startup; each is a buffer-local toggle, off until asked for.
(setq olivetti-body-width 80)   ; text column width, in characters
(setq darkroom-text-scale-increase 1)
(global-set-key (kbd "C-c o") #'olivetti-mode)
(global-set-key (kbd "C-c w") #'writeroom-mode)
(global-set-key (kbd "C-c d") #'darkroom-tentative-mode)

;; --- CSV --------------------------------------------------------------------
;; csv-mode (GNU ELPA): major mode for delimited files; its autoloads already
;; register .csv/.tsv/.tab in `auto-mode-alist', but require it eagerly so the
;; hooks and keybinding below have `csv-mode-map' available at startup.
(require 'csv-mode)
;; rainbow-csv: tints each column a distinct colour so fields line up visually.
;; Turn it on automatically in both csv- and tsv-mode buffers.
(require 'rainbow-csv)
(add-hook 'csv-mode-hook #'rainbow-csv-mode)
(add-hook 'tsv-mode-hook #'rainbow-csv-mode)
;; Casual CSV (from the `casual' suite on MELPA): a Transient menu exposing
;; csv-mode's commands. Bind its entry point to M-m in csv-mode buffers, the key
;; the package's own docs recommend. `casual-csv-tmenu' is autoloaded, so no
;; extra `require' is needed for the menu itself.
(keymap-set csv-mode-map "M-m" #'casual-csv-tmenu)

;; --- vterm ------------------------------------------------------------------
;; Fully-featured terminal emulator backed by a native module. The module is
;; compiled on first use and needs cmake + libtool installed on the system.
;; Keep it autoloaded rather than requiring it during init: when the module is
;; absent, vterm asks whether to compile it, and a minibuffer prompt during
;; startup can abort the whole initialization (notably for daemon sessions).
;; package.el has already installed vterm and registered its autoloads above.

;; --- claude-code-ide --------------------------------------------------------
;; Runs the Claude Code CLI inside a vterm buffer with IDE integration.
(require 'claude-code-ide)

;; --- codex-ide --------------------------------------------------------------
;; Pure-Emacs client for the Codex CLI (no vterm): syntax-highlighted output,
;; native diffs and in-buffer approval flows. `C-c C-;' opens its transient menu.
(require 'codex-ide)
(global-set-key (kbd "C-c C-;") #'codex-ide-menu)

;; --- pdf-tools --------------------------------------------------------------
;; Renders PDFs as images (via a native `epdfinfo' server built from poppler)
;; instead of DocView's page-image conversion: crisp text, isearch, links,
;; annotations and continuous scrolling. `pdf-loader-install' wires up the
;; autoloads and defers loading pdf-tools (and the one-time epdfinfo build,
;; which needs poppler + glib development headers) until the first PDF is
;; opened -- so don't `require' pdf-tools eagerly here, or that build would be
;; triggered at every startup instead of lazily.
(pdf-loader-install)

;; --- modeline (doom-modeline + minions) -------------------------------------
;; doom-modeline: a compact, informative mode-line lifted from Doom Emacs.
;; minions: collapses the cluster of enabled minor-mode lighters into a single
;; menu so the mode-line stays clean. Telling doom-modeline to show minor modes
;; makes it route them through minions' menu.
(require 'doom-modeline)
(require 'minions)
(require 'nerd-icons)
(setq doom-modeline-minor-modes t)

;; Custom segment: the Emacs logo plus the host OS logo (Tux), drawn as
;; Nerd Font glyphs (so they inherit the mode-line face and scale with the
;; font). `nf-custom-emacs' is the Emacs icon; `nf-linux-tux' is the penguin.
(doom-modeline-def-segment os-emacs-logos
  (concat (doom-modeline-spc)
          (nerd-icons-sucicon "nf-custom-emacs" :v-adjust 0.0)
          (doom-modeline-vspc)
          (nerd-icons-flicon "nf-linux-tux" :v-adjust 0.0)
          (doom-modeline-spc)))

;; Redefine the `main' mode-line with `os-emacs-logos' prepended to the left
;; side. The two segment lists below mirror doom-modeline's upstream default
;; for `main' (see `doom-modeline.el'); if doom-modeline changes its defaults
;; in a future update, re-sync these lists.
(doom-modeline-def-modeline 'main
  '(os-emacs-logos eldoc bar window-state workspace-name window-number modals matches follow buffer-info remote-host buffer-position word-count parrot selection-info)
  '(compilation objed-state misc-info project-name persp-name battery grip irc mu4e gnus github debug repl lsp minor-modes input-method indent-info buffer-encoding major-mode process vcs check time))

(minions-mode 1)
(doom-modeline-mode 1)

;; --- Themes (ef-themes + solarized + doom-themes) ----------------------------
;; Three theme collections are installed; only one theme is ever active, and
;; `ef-elea-light' below is it. The other two are here to switch to with
;; M-x load-theme, so they are deliberately not `require'd or loaded: a theme
;; pack costs nothing until a theme from it is loaded, and each package's
;; autoloads already add its directory to `custom-theme-load-path', which is all
;; `load-theme' and `custom-available-themes' need to find them.
;;
;; Themes stack rather than replace, so `load-theme' on top of a live theme
;; leaves the old one's faces showing through wherever the new one is silent.
;; M-x disable-theme (or ef-themes' own commands, which do this for you) first.
;;
;;   ef-themes        -- Protesilaos' legible light/dark pairs (13 x 2).
;;                       M-x ef-themes-select, or ef-themes-toggle for the pair
;;                       named in `ef-themes-to-toggle' below.
;;   solarized-theme  -- bbatsov's Emacs port of Ethan Schoonover's Solarized;
;;                       13 variants (solarized-light/-dark, the -high-contrast
;;                       and -selenized-* sets, plus gruvbox/wombat/zenburn).
;;   doom-themes      -- the Doom Emacs collection, 77 themes (doom-one,
;;                       doom-nord, doom-gruvbox, doom-tokyo-night, ...).
;;                       Its optional extras (`doom-themes-visual-bell-config',
;;                       `doom-themes-org-config') need an explicit
;;                       (require 'doom-themes) and are not enabled here.
(require 'ef-themes)
(setq ef-themes-to-toggle '(ef-elea-light ef-elea-dark))
(load-theme 'ef-elea-light :no-confirm)

;; --- Line numbers + current-line highlight ----------------------------------
;; Enabled per-mode rather than globally: line numbers and a highlighted row are
;; noise (and sometimes actively broken) in vterm, pdf-view, image and other
;; non-editing buffers.
;; `display-line-numbers-width-start' sizes the number column to the buffer's
;; longest line up front, so text doesn't shift sideways while scrolling.
(setq display-line-numbers-width-start t)
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode)
  (add-hook hook #'hl-line-mode))

;; --- Default font -----------------------------------------------------------
;; JuliaMono Nerd Font Mono (includes Nerd Font glyphs/icons). Applies to the
;; current and all future frames.
(set-face-attribute 'default nil :family "JuliaMono Nerd Font Mono" :height 130)
(add-to-list 'default-frame-alist '(font . "JuliaMono Nerd Font Mono-13"))

;; --- Git (magit + diff-hl) --------------------------------------------------
;; magit: the Git porcelain. Autoloaded, so just bind the usual entry point
;; rather than `require'-ing the whole thing at startup.
(global-set-key (kbd "C-x g") #'magit-status)
;; diff-hl: show added/changed/removed lines in the fringe, live, in every
;; file-visiting buffer. Keep its indicators in sync with magit commits/stages.
(require 'diff-hl)
(global-diff-hl-mode 1)
(add-hook 'magit-pre-refresh-hook #'diff-hl-magit-pre-refresh)
(add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)

;; --- Completion UI (corfu) --------------------------------------------------
;; The piece that was missing. Both LSP clients below publish their candidates
;; through the standard `completion-at-point-functions' hook, but stock Emacs
;; only renders those into a *Completions* buffer on an explicit C-M-i -- which
;; reads, at the point of use, as "the language server isn't doing anything".
;; corfu draws them as an in-buffer popup as you type, which is what makes any
;; of this visible. It is UI only: it knows nothing about LSP, and serves the
;; TeX, Python, Julia and R servers alike.
(global-corfu-mode 1)
(setq corfu-auto t)            ; pop up without waiting for an explicit C-M-i
(setq corfu-auto-prefix 2)     ; ...after 2 chars, so `\be' already suggests
(setq corfu-auto-delay 0.1)
(setq corfu-cycle t)
;; TAB-driven completion: let TAB both indent and complete, which is the
;; interaction corfu is built around.
(setq tab-always-indent 'complete)

;; Documentation alongside the completion candidates: a second popup, showing
;; the selected candidate's signature and docstring. digestif sends both (it
;; knows `\section' takes `*[short title]{title}'), so this is what turns the
;; candidate list from bare names into something you can choose from. Ships
;; with corfu -- no extra package.
(with-eval-after-load 'corfu
  (require 'corfu-popupinfo)
  (corfu-popupinfo-mode 1)
  (setq corfu-popupinfo-delay '(0.3 . 0.2)))   ; (initial . subsequent)

;; --- Help popups (eldoc) ----------------------------------------------------
;; Point-idle help: command signature and documentation, which for TeX means
;; digestif's own description plus the matching node of the LaTeX reference
;; manual (latex2e.info, already installed under /usr/share/info -- digestif
;; shells out to /usr/bin/info to pull it in, which is why the README asks for
;; it). eglot feeds all of that to eldoc.
;;
;; Two stock-eldoc defaults get in the way of actually reading it:
;;
;; 1. `eldoc-documentation-default' shows only the FIRST source that returns
;;    anything, so eglot's hover and its signature-help shadow each other --
;;    you get one or the other. `eldoc-documentation-compose' shows both.
;; 2. The echo area is one line. A full info node is not a one-line object, so
;;    it arrives truncated to uselessness -- which is what "no documentation"
;;    tends to look like in practice.
(setq eldoc-documentation-strategy #'eldoc-documentation-compose)
(setq eldoc-echo-area-use-multiline-p 3)   ; up to 3 lines in the echo area
(setq eldoc-idle-delay 0.2)

;; eldoc-box renders that same eldoc output in a childframe at point -- the
;; actual "popup help message". C-h . (`eldoc-doc-buffer') remains the fallback
;; for the full, scrollable text when a node is longer than the box.
(when (display-graphic-p)
  (add-hook 'eglot-managed-mode-hook #'eldoc-box-hover-at-point-mode))
(setq eldoc-box-max-pixel-width 600)
(setq eldoc-box-max-pixel-height 500)
(setq eldoc-box-clear-with-C-g t)

;; --- LSP: TeX (eglot + digestif) --------------------------------------------
;; TeX is driven by eglot, Emacs' built-in LSP client -- nothing to install on
;; Emacs 30. digestif is the server: it ships with TeX Live and is already at
;; /usr/bin/digestif, and it is the pairing digestif's own README documents.
;; eglot 30 has no TeX entry out of the box, so register one. The executable is
;; spelled out in full because a desktop-launched Emacs does not reliably
;; inherit a login shell's PATH.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((tex-mode latex-mode plain-tex-mode context-mode texinfo-mode)
                 . ("/usr/bin/digestif"))))

;; --- LSP: everything else (lsp-mode) ----------------------------------------
;; lsp-mode still drives Python (pylsp), Julia (JETLS) and R (languageserver).
;; It and eglot cover disjoint major modes, so the two clients coexist without
;; fighting over a buffer. lsp-mode is autoloaded, but require it here so the
;; per-mode hooks and the JETLS client registration below have it loaded at
;; startup. `lsp-deferred' starts a server only once a matching buffer is
;; actually visited, so this stays cheap.
(require 'lsp-mode)

;; Start a server on the file's own directory when the buffer isn't inside a
;; recognised project. lsp-mode's root detection only finds VC roots, so a
;; scratch directory with no .git (a bare ~/juliaTest, say) otherwise makes it
;; block on an interactive "import project root?" prompt instead of connecting.
(setq lsp-auto-guess-root t)

;; Completions are drawn by corfu, not company, so stop lsp-mode from trying to
;; autoconfigure company on every connection (it warns "Unable to autoconfigure
;; company-mode" and fails). `:none' leaves `lsp-completion-at-point' on
;; `completion-at-point-functions', which is exactly what corfu consumes.
(setq lsp-completion-provider :none)

;; Snippet support needs yasnippet, which isn't installed; leaving this on just
;; produces a warning on every connection and no snippets either way.
(setq lsp-enable-snippet nil)

;; Python: point pylsp at the dedicated `emacs-lsp' conda env so the server is
;; found regardless of which project/conda env is active. (Installed with
;; `conda create -n emacs-lsp -c conda-forge python-lsp-server'.)
(setq lsp-pylsp-server-command
      '("/home/simon/miniconda3/envs/emacs-lsp/bin/pylsp"))

;; Julia: JETLS is not a bundled lsp-mode client, so register it by hand. It
;; speaks standard LSP over stdio; `jetls' lives in ~/.julia/bin (on PATH via
;; juliaup). Requires Julia >= 1.12.2.
(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-language-id-configuration '(julia-mode . "julia"))
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection '("jetls" "serve" "--stdio"))
    :major-modes '(julia-mode)
    :language-id "julia"
    :server-id 'jetls)))

;; The ChkTeX settings that used to live here were texlab-specific (it is texlab
;; that shells out to ChkTeX; digestif does not), so they went with it. digestif
;; is quiet by comparison -- it reports unknown commands and bad references, and
;; does not lint half-typed macros -- so there is no equivalent noise to tame.

;; Auto-close braces in TeX buffers, so `\begin{' immediately becomes `\begin{}'
;; with point between them. Wanted in its own right, and it keeps the buffer out
;; of the unbalanced-brace states that make any TeX server's diagnostics thrash.
(add-hook 'tex-mode-hook #'electric-pair-local-mode)
(add-hook 'latex-mode-hook #'electric-pair-local-mode)

;; Start a server automatically when visiting a matching buffer. TeX goes to
;; eglot (digestif), everything else to lsp-mode; `eglot-ensure' and
;; `lsp-deferred' both wait until the buffer is actually visited.
(dolist (hook '(tex-mode-hook
                latex-mode-hook
                LaTeX-mode-hook))      ; AUCTeX, if ever installed
  (add-hook hook #'eglot-ensure))

;; R support (lsp-mode's lsp-r client) attaches to ESS's `ess-r-mode'.
(dolist (hook '(python-mode-hook
                python-ts-mode-hook
                julia-mode-hook
                ess-r-mode-hook))
  (add-hook hook #'lsp-deferred))

;; --- Email (mu4e) -----------------------------------------------------------
;; mu4e ships with the Debian `mu4e' package (the `mu' indexer comes from
;; `maildir-utils'). The package drops its Lisp in the site-lisp tree below;
;; add it to `load-path' explicitly so `require' finds it. The Debian package
;; installs under /usr/share/emacs/site-lisp/elpa/mu4e-<version>/, and that
;; version is baked into the directory name, so glob for it rather than pinning
;; a version that a future `apt upgrade' would change out from under us.
;; mu4e is the front end only -- mail is fetched by OfflineIMAP into ~/.maildir
;; and indexed by `mu', and sent via msmtp.
(let ((mu4e-dir (car (last (file-expand-wildcards
                            "/usr/share/emacs/site-lisp/elpa/mu4e-*")))))
  (when mu4e-dir
    (add-to-list 'load-path mu4e-dir)))
;; Mail is an optional system-level component.  Do not make a missing Debian
;; package fatal to all of Emacs; the settings below remain ready for whenever
;; mu4e is installed.
(require 'mu4e nil :noerror)

;; Where OfflineIMAP writes the maildir, and how mu4e refreshes it. `-o -q' runs
;; a quick, one-shot sync (no held connection); drop `-q' for a full sync.
(setq mu4e-maildir "~/.maildir")
(setq mu4e-get-mail-command "offlineimap -o -q")
(setq mu4e-update-interval 300)               ; auto-sync every 5 minutes
;; OfflineIMAP (like mbsync) rewrites message filenames on sync, so mu4e must
;; rename rather than assume stable names -- required or moves/flags desync.
(setq mu4e-change-filenames-when-moving t)
(setq mu4e-attachment-dir "~/Downloads")

;; Gmail's special folders, as they appear under ~/.maildir/gmail. OfflineIMAP
;; flattens Gmail's "[Gmail]/X" hierarchy into single dotted directory names
;; ("[Gmail].Sent Mail"), so the mu4e paths use a dot, not a slash. The single
;; account lives beneath /gmail, so every path is prefixed with it.
(setq mu4e-drafts-folder "/gmail/[Gmail].Drafts")
(setq mu4e-sent-folder   "/gmail/[Gmail].Sent Mail")
;; This account's Gmail locale is UK English, so the system trash arrives as
;; "Bin". A separate, user-created "[Gmail]/Trash" label also exists and is NOT
;; the real trash -- pointing mu4e there files deletions into a dead label.
(setq mu4e-trash-folder  "/gmail/[Gmail].Bin")
(setq mu4e-refile-folder "/gmail/[Gmail].All Mail")
;; Gmail keeps its own copy of everything you send (via IMAP), so telling mu4e
;; to also file a copy would duplicate it. `delete' = hand off to Gmail.
(setq mu4e-sent-messages-behavior 'delete)

;; Jump-to-folder shortcuts (the `j' command in the headers/main view). Every
;; maildir OfflineIMAP syncs gets a key, so this list mirrors the Gmail label
;; set; add a line here when a new label appears. `training', `sociology' and
;; `it' are real labels that are simply empty inside the 90-day `maxage' window.
(setq mu4e-maildir-shortcuts
      '(;; System folders.
        (:maildir "/gmail/INBOX"             :key ?i)
        (:maildir "/gmail/[Gmail].All Mail"  :key ?a)
        (:maildir "/gmail/[Gmail].Sent Mail" :key ?s)
        (:maildir "/gmail/[Gmail].Drafts"    :key ?d)
        (:maildir "/gmail/[Gmail].Bin"       :key ?t)
        (:maildir "/gmail/[Gmail].Spam"      :key ?S)
        (:maildir "/gmail/[Gmail].Starred"   :key ?*)
        ;; Labels.
        (:maildir "/gmail/@citystgeorges"    :key ?c)
        (:maildir "/gmail/ba"                :key ?b)
        (:maildir "/gmail/phd"               :key ?p)
        (:maildir "/gmail/grants"            :key ?g)
        (:maildir "/gmail/research"          :key ?r)
        (:maildir "/gmail/community"         :key ?m)
        (:maildir "/gmail/admin"             :key ?n)
        (:maildir "/gmail/travels"           :key ?v)
        (:maildir "/gmail/lbs"               :key ?l)
        (:maildir "/gmail/teaching"          :key ?e)
        (:maildir "/gmail/conferences"       :key ?f)
        (:maildir "/gmail/career"            :key ?k)
        (:maildir "/gmail/review"            :key ?w)
        (:maildir "/gmail/outreach"          :key ?u)
        (:maildir "/gmail/computing"         :key ?o)
        (:maildir "/gmail/training"          :key ?y)
        (:maildir "/gmail/sociology"         :key ?z)
        (:maildir "/gmail/it"                :key ?x)))

;; Identity.
(setq user-mail-address "sim.santoni@gmail.com")
(setq user-full-name    "Simone Santoni")

;; Sending: hand the message to msmtp, which authenticates to Gmail's SMTP with
;; the app password (see ~/.msmtprc). `--read-envelope-from' makes msmtp pick
;; the account from the From: header; `message-sendmail-f-is-evil' stops Emacs
;; passing a `-f' that would fight msmtp's own envelope handling.
(setq message-send-mail-function 'message-send-mail-with-sendmail)
(setq sendmail-program "/usr/bin/msmtp")
(setq message-sendmail-extra-arguments '("--read-envelope-from"))
(setq message-sendmail-f-is-evil t)

;; C-c m from anywhere opens mu4e.
(global-set-key (kbd "C-c m") #'mu4e)

;; --- Chat (zulip) -----------------------------------------------------------
;; A native Zulip client: no external process, just Emacs' own url.el against
;; Zulip's REST API. Entry points are `zulip-login' (connect), `zulip-home'
;; (dashboard), `zulip-channels', `zulip-dms' and `zulip-compose'.
;;
;; The README says to `(require 'zulip)', but every entry point carries an
;; autoload cookie, so binding one is enough -- and it keeps a chat client out of
;; startup, the same reason magit above is bound rather than required.
;;
;; Credentials come from a zuliprc file: an INI file holding [api] email/key/site.
;;
;; The package defaults `zulip-rc-file' to ~/.zuliprc (dotted), but the file on
;; this machine is ~/zuliprc (undotted) -- which is where zulip-terminal, the
;; official TUI, tells you to save the one you download from Zulip's web UI
;; (Settings > Account & privacy > API key). Left at the default, `zulip-login'
;; finds no accounts and silently falls through to prompting for server, email
;; and key by hand -- so point it at the real file rather than retyping a key.
(setq zulip-rc-file "~/zuliprc")

;; Upstream bug workaround: this realm restricts email visibility, so Zulip's
;; /users/me answers with a stand-in address (user<id>@<realm>) in `email' and
;; the real one in `delivery_email'. `zulip--do-login' takes `email' to be
;; canonical and writes it into the connection, but an API key only authenticates
;; against the real address -- so the swap silently logs us out. Login's own
;; profile fetch still succeeds, having run before the swap, and the next call
;; (POST /register) comes back 401 "Invalid API key", which surfaces only as the
;; generic "Zulip: failed to register event queue".
;;
;; Rather than advise `zulip--do-login' (a long function whose swap is buried
;; mid-body), hand it a profile whose `email' already IS the delivery address, so
;; its swap becomes a no-op. Remove this if upstream starts preferring
;; `delivery_email'; it is written to be inert if they do, and on realms that do
;; not restrict visibility (where the two fields are equal) it changes nothing.
(defun zulip--prefer-delivery-email (data)
  "Return profile DATA with `email' replaced by `delivery_email' when present."
  (when (hash-table-p data)
    (let ((delivery (gethash "delivery_email" data)))
      (when (and (stringp delivery) (not (string-empty-p delivery)))
        (puthash "email" delivery data))))
  data)
(with-eval-after-load 'zulip
  (advice-add 'zulip--api-get-profile-sync :filter-return
              #'zulip--prefer-delivery-email))
;;
;; `zulip-doom' in the same package registers SPC leader bindings for Doom
;; Emacs' evil setup; this is a vanilla config, so it is deliberately not loaded.
(global-set-key (kbd "C-c z") #'zulip-home)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-vc-selected-packages
   '((emacs-zulip :vc-backend Git :url
		  "https://github.com/suky57/emacs-zulip")
     (rainbow-csv :vc-backend Git :url
		  "https://github.com/emacs-vs/rainbow-csv")
     (emacs-codex-ide :vc-backend Git :url
		      "https://github.com/dgillis/emacs-codex-ide")
     (claude-code-ide :vc-backend Git :url
		      "https://github.com/manzaltu/claude-code-ide.el"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
