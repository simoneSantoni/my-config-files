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

;; This org-roam-ui release triggers false undefined-function diagnostics for
;; its obsolete aliases and optional ORB integration during native compilation.
;; Keep its byte-compiled implementation; other packages still compile normally.
(with-eval-after-load 'comp-run
  (add-to-list 'native-comp-jit-compilation-deny-list "org-roam-ui\\.el\\'"))

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

;; compat needs its own guard. Emacs 30 ships a *stub* `compat' package
;; (version 30.2.9999, "Stub of the Compatibility Library") that defines
;; nothing, and package.el counts it as built-in. So `package-installed-p' is t
;; even when the real archive package is absent (the `required-packages' loop
;; below would never install it on a fresh machine), `package-upgrade-all'
;; skips it, and `package-upgrade' deletes the old copy and then declines to
;; install the new one -- seen 2026-10, when an upgrade left no compat on disk
;; and transient broke on `static-when'. `package-alist' lists only real
;; installs, never the stub, so test that and install from the archive
;; descriptor, which bypasses the built-in check. It sits up here, ahead of the
;; loop, because Org from Git (next) declares (compat "31") as well.
(unless (assq 'compat package-alist)
  (unless (assq 'compat package-archive-contents)
    (package-refresh-contents))
  (let ((package-install-upgrade-built-in t))
    (package-install (cadr (assq 'compat package-archive-contents)))))

;; --- Org from Git `main' (for org-latex-preview) -----------------------------
;; org-latex-preview -- tecosaur and Karthik Chikmagalur's rewrite of org's LaTeX
;; previews (async, cached, live while you type, numbered equations; see
;; https://abode.karthinks.com/org-latex-preview/) -- is not a package: it is
;; lisp/org-latex-preview.el inside Org itself, on Org's `main' branch, due in
;; Org 10.0. Emacs 30.2 bundles Org 9.7.11, so getting it means replacing the
;; built-in Org with `main', installed with `package-vc-install' as below (the
;; recipe from that page). The package is named `org', not `org-mode', so every
;; package that declares a dependency on `org' (org-roam, citar, org-ql, ...)
;; is satisfied by this copy rather than pulling 9.7 from GNU ELPA.
;;
;; Four details, each of which breaks the install if got wrong:
;;
;;   - it runs *before* the `required-packages' loop. Those packages are
;;     byte-compiled on install against whichever Org is on `load-path' at the
;;     time, and Org macros expanded under 9.7 into an .elc that then runs
;;     under 10.0 is the "mixed install" the page warns about. After switching
;;     an existing machine over, M-x package-recompile-all clears that up.
;;   - the guard is `package-alist', not `package-installed-p' -- the same trap
;;     as compat above: Org is in `package--builtins', so `package-installed-p'
;;     is t on a stock Emacs and this would never run.
;;   - `package-vc-allow-build-commands' must name `org'. Emacs 30 silently
;;     skips a spec's `:make' unless it does, and without `make autoloads' the
;;     checkout has no org-loaddefs.el or org-version.el of its own, so
;;     `load-path' finds the *built-in* ones -- a mixed install out of the box.
;;     It is a global setq rather than a `let' around the install so that
;;     M-x package-vc-upgrade RET org RET rebuilds them too. Only `org' is
;;     listed: the setting runs arbitrary make targets, so it stays opt-in.
;;   - `:make' is a plain list here. The page writes `:make '("autoloads"
;;     "info")' *inside* the already-quoted spec, which hands package-vc the
;;     list (quote ("autoloads" "info")) and `make' the argument "quote".
;;
;; The build needs `make' and `makeinfo' (texinfo). The previews themselves need
;; a TeX distribution and dvisvgm with Ghostscript (`dvisvgm --version=yes');
;; the settings are in the "Org LaTeX previews" section further down.
(setq package-vc-allow-build-commands '(org))
(unless (assq 'org package-alist)
  (package-vc-install
   '(org :url "https://git.savannah.gnu.org/git/emacs/org-mode.git"
         :lisp-dir "lisp"
         :make ("autoloads" "info")
         :doc "doc/org.texi")))

;; Ensure every third-party package this init `require's is actually installed.
;; A fresh checkout (or a freshly wiped elpa/) has no packages, so the bare
;; `require' calls below would fail with "Cannot open load file". Install any
;; that are missing, refreshing the archive cache once if a name isn't found.
(let ((required-packages '(exec-path-from-shell
                           compat
                           markdown-mode
                           markdown-toc
                           mermaid-mode
                           olivetti
                           writeroom-mode
                           darkroom
                           csv-mode
                           casual
                           ;; pg (pg-el): the pure-Elisp PostgreSQL wire client
                           ;; that pgmacs (installed from Git below) is built on.
                           pg
                           vterm
                           ghostel
                           pdf-tools
                           ;; treemacs already arrives as a dap-mode dependency;
                           ;; naming it here makes the tree explorer a package
                           ;; this config owns rather than an accident of the
                           ;; debugger's dependency graph.
                           treemacs
                           calfw
                           calfw-org
                           calfw-cal
                           doom-modeline
                           minions
                           nerd-icons
                           all-the-icons
                           ef-themes
                           solarized-theme
                           doom-themes
                           magit
                           diff-hl
                           lsp-mode
                           lsp-pyright
                           consult-lsp
                           dap-mode
                           yasnippet
                           yasnippet-snippets
                           yasnippet-capf
                           envrc
                           corfu
                           cape
                           vertico
                           orderless
                           marginalia
                           consult
                           embark
                           embark-consult
                           eldoc-box
                           julia-mode
                           julia-repl
                           ess
                           reformatter
                           quarto-mode
                           rainbow-delimiters
                           org-roam
                           org-download
                           org-roam-ql
                           org-roam-bibtex
                           org-roam-ui
                           ;; citar arrives as a citar-org-roam dependency, but
                           ;; it is configured directly further down, so name it
                           ;; here rather than let it look like an orphan.
                           citar
                           citar-org-roam
                           org-ref
                           ;; Annotates PDFs into the reading's org-roam node;
                           ;; configured in slimer's org-config.el with the rest
                           ;; of the reference stack.
                           org-noter
                           smudge)))
  (dolist (pkg required-packages)
    (unless (package-installed-p pkg)
      (unless (assq pkg package-archive-contents)
        (package-refresh-contents))
      (package-install pkg)))
  ;; Record the full set as "selected". package.el only marks packages at
  ;; install time, and the Custom block at the bottom of this file used to pin
  ;; `package-selected-packages' back to nil on every startup -- which made
  ;; `M-x package-autoremove' regard every installed package as an orphan
  ;; eligible for deletion. The Git-installed packages (below) are appended
  ;; because autoremove consults this same list for them; keep both lists in
  ;; sync when adding or dropping a package.
  (setq package-selected-packages
        (append required-packages
                '(gnu-elpa-keyring-update
                  claude-code-ide emacs-codex-ide rainbow-csv emacs-zulip
                  dired-sidebar org-sidebar all-the-icons-dired
                  insert-uuid mathpix org foxglove-themes))))

;; Mathpix is installed from upstream Git, alongside the archive packages above.
(unless (package-installed-p 'mathpix)
  (package-vc-install '(mathpix :url "https://github.com/jethrokuan/mathpix.el")))

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

;; MELPA occasionally advertises a dired-sidebar snapshot before its tarball is
;; available. Install from the requested upstream repository instead; its sole
;; required package, `dired-subtree', is resolved from MELPA automatically.
;; `package-vc-install' also compiles generated internal forms, which have no
;; source-file cookie and otherwise produce a spurious lexical-binding warning.
;; Suppress only that cookie check while installing; all substantive compiler
;; warnings remain enabled.
(unless (package-installed-p 'dired-sidebar)
  (require 'bytecomp)
  (let ((bytecomp--inhibit-lexical-cookie-warning t))
    (package-vc-install "https://github.com/jojojames/dired-sidebar")))

;; org-sidebar is installed from its requested upstream repository. Its
;; Package-Requires header lets package-vc resolve org-ql and the remaining
;; dependencies from the configured archives.
(unless (package-installed-p 'org-sidebar)
  (require 'bytecomp)
  (let ((bytecomp--inhibit-lexical-cookie-warning t))
    (package-vc-install "https://github.com/alphapapa/org-sidebar")))

;; Add all-the-icons glyphs to ordinary Dired buffers. Install the requested
;; integration from upstream; the icon library itself comes from MELPA above.
(unless (package-installed-p 'all-the-icons-dired)
  (require 'bytecomp)
  (let ((bytecomp--inhibit-lexical-cookie-warning t))
    (package-vc-install "https://github.com/jtbm37/all-the-icons-dired")))

;; insert-uuid: an RFC 4122 UUID generator (M-x insert-uuid), not on any
;; archive. No dependencies beyond Emacs 27.1.
(unless (package-installed-p 'insert-uuid)
  (package-vc-install "https://github.com/theesfeld/insert-uuid"))

;; pgmacs: a table-oriented PostgreSQL browser/editor (M-x pgmacs), not on any
;; archive. Its Package-Requires names `pg' (>= 0.64), which `required-packages'
;; above already satisfies from MELPA, so package-vc has nothing left to
;; resolve. Upgrade with M-x package-vc-upgrade RET pgmacs RET.
(unless (package-installed-p 'pgmacs)
  (package-vc-install "https://github.com/emarsden/pgmacs"))

;; foxglove-themes: Vegas Harmon's ink-on-paper Modus derivatives (six themes;
;; see the Themes section), GitLab-only. The repository name is the package
;; name, so there is no codex/zulip-style naming trap. Its Package-Requires names
;; `modus-themes' (>= 5.0), already on disk as an ef-themes dependency.
(unless (package-installed-p 'foxglove-themes)
  (package-vc-install "https://gitlab.com/vegasharmon/foxglove-themes"))

;; Import PATH (and other env) from the shell. GUI Emacs launched from a
;; desktop launcher gets a minimal PATH that omits ~/.local/bin, so tools like
;; the `claude' CLI used by claude-code-ide aren't found. This fixes that.
;;
;; `exec-path-from-shell-arguments' defaults to '("-l" "-i") — an interactive
;; login shell — which made startup pay for the whole of ~/.zshrc: oh-my-zsh,
;; compinit, zinit and its annexes, nvm, fastfetch. That took ~1s and tripped
;; exec-path-from-shell's own "execution took %dms" warning (it complains past
;; `exec-path-from-shell-warn-duration-millis', 500ms). PATH now lives in
;; ~/.zshenv, which zsh sources on *every* invocation, so a bare `zsh -c' sees
;; the full PATH and nil here skips both rc files entirely (~20ms). If PATH
;; ever moves back into ~/.zshrc this must go back to '("-l" "-i").
(require 'exec-path-from-shell)
(setq exec-path-from-shell-arguments nil)
(when (or (memq window-system '(mac ns x pgtk))
          (daemonp))
  (exec-path-from-shell-initialize))

;; Load compat early. transient (a claude-code-ide dependency) uses macros such
;; as `static-when' that ship in compat but not in Emacs 30.x. Ensuring compat
;; is loaded first guarantees those macros are defined before transient loads.
(require 'compat)

;; --- File sidebar -----------------------------------------------------------
;; A lightweight project/file tree backed by Dired. Keep it autoloaded so it
;; adds no startup work until the sidebar is first opened.
;;
;; Icons come from `all-the-icons-dired-mode' on `dired-mode-hook' — with that
;; hook present dired-sidebar deliberately disables its own icon theming
;; (`dired-sidebar-block-icon-display-modes', upstream issue #43), so the
;; `dired-sidebar-theme' value is inert and dired-sidebar's built-in
;; refresh-after-unfold never fires. all-the-icons-dired itself only redraws on
;; `dired-readin'/`dired-revert' & co., which `dired-subtree-toggle' bypasses,
;; so lines revealed by unfolding had no icons until a manual `g'. Hooking the
;; refresh onto `dired-subtree-after-insert-hook' fixes that in the sidebar and
;; in ordinary dired buffers alike (collapsing needs nothing: the overlays die
;; with the deleted lines).
(setq dired-sidebar-theme 'nerd-icons)
(global-set-key (kbd "C-x C-n") #'dired-sidebar-toggle-sidebar)
(add-hook 'dired-mode-hook #'all-the-icons-dired-mode)
(defun my/all-the-icons-dired-subtree-refresh ()
  "Redraw all-the-icons-dired icons after a dired-subtree insertion."
  (when (bound-and-true-p all-the-icons-dired-mode)
    (all-the-icons-dired--refresh)))
(with-eval-after-load 'dired-subtree
  (add-hook 'dired-subtree-after-insert-hook
            #'my/all-the-icons-dired-subtree-refresh))

;; --- Project tree (treemacs) -------------------------------------------------
;; The second sidebar, deliberately kept alongside dired-sidebar rather than
;; replacing it: dired-sidebar is a Dired buffer (every Dired key works, one
;; directory at a time), treemacs is a persistent multi-project workspace with
;; its own state file, git status decoration and follow-mode. `C-x t' is the
;; prefix treemacs' own README uses, and it is free in Emacs 30 apart from the
;; tab-bar map, which this config does not use.
;;
;; treemacs was already on disk as a dap-mode dependency (dap-mode's UI is
;; built on treemacs, which is why `dap-python' is required inside the
;; python-mode hook and not at startup); it is now named in
;; `required-packages' above so it is owned rather than inherited. Nothing is
;; `require'd here -- every entry point below is autoloaded, and treemacs
;; reads its persisted workspace only when first opened.
;;
;; Icons: treemacs ships its own PNG/text themes and does not go through
;; nerd-icons, so no icon wiring is needed (and none of the dired-sidebar
;; workaround above applies). Git decoration needs a `git' binary plus Python 3
;; for the "deferred" (asynchronous, per-file) mode; `simple' mode below is the
;; pure-Elisp fallback that needs neither, chosen so a machine without Python 3
;; on PATH degrades quietly instead of erroring at first open.
(global-set-key (kbd "C-x t t") #'treemacs)
(global-set-key (kbd "C-x t d") #'treemacs-select-directory)
(global-set-key (kbd "C-x t B") #'treemacs-bookmark)
(global-set-key (kbd "C-x t C-t") #'treemacs-find-file)
(setq treemacs-git-mode 'simple
      treemacs-follow-after-init t
      treemacs-width 32
      ;; Persisted workspaces are data, not config -- same policy as the diary
      ;; and the org-roam database below.
      treemacs-persist-file (expand-file-name "treemacs-persist" user-emacs-directory))

;; --- Markdown ---------------------------------------------------------------
;; markdown-mode: major mode for editing Markdown; use it for .md/.markdown.
(require 'markdown-mode)
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
;; markdown-toc: generate/refresh a table of contents (M-x markdown-toc-generate-toc).
(require 'markdown-toc)
;; mermaid-mode (MELPA, abrochard/mermaid-mode): major mode for Mermaid diagram
;; files. Its autoloads already claim .mmd, so a plain `require' just makes the
;; mode (syntax highlighting, indentation) available eagerly like markdown-mode
;; above. Compiling/previewing a diagram (C-c C-c and friends) shells out to the
;; mermaid-cli `mmdc' binary, which is NOT installed on this machine -- editing
;; works regardless; install it (npm install -g @mermaid-js/mermaid-cli) if
;; rendering from Emacs is ever wanted.
(require 'mermaid-mode)

;; --- Org display (inline images) ---------------------------------------------
;; Show image links as images when an org file is visited, instead of leaving
;; every figure as a bare [[file:...]] line to be revealed by hand. This is the
;; startup variable rather than `(add-hook 'org-mode-hook
;; #'org-toggle-inline-images)': the hook route runs a *toggle*, so it depends on
;; the buffer's state at that moment and flips images back off wherever they are
;; already displayed -- a file carrying `#+STARTUP: inlineimages', or org having
;; drawn them itself during setup. `org-startup-with-inline-images' is the state
;; org checks after that setup, so it lands on "on" every time, and a single file
;; can still opt out with `#+STARTUP: noinlineimages'. `C-c C-x C-v'
;; (`org-toggle-inline-images') stays the manual control -- still needed after an
;; image is generated mid-session (babel results, a newly added figure), which
;; does not re-run startup.
(setq org-startup-with-inline-images t)

;; --- Org LaTeX previews (org-latex-preview) ----------------------------------
;; Org 10's preview engine, from the Org `main' install near the top of this
;; file. `org-latex-preview-mode' renders each fragment as an image once point
;; leaves it and reveals the source when point enters it, compiling in the
;; background and caching the images (through org-persist) so a note re-opens
;; without recompiling. It replaces org-fragtog and org-latex-impatient, which
;; would fight it -- neither is installed, keep it that way. C-c C-x C-l
;; (`org-latex-preview') still previews or clears a region or buffer by hand.
;;
;; The settings are the ones the abode.karthinks.com page suggests:
;;   - `:page-width' 0.8 (default 0.6) widens the LaTeX page each fragment is
;;     typeset on, so long display equations wrap later.
;;   - `org-latex-preview-mode-display-live' t shows a live-updating render
;;     beside the fragment being edited -- inline fragments included, where
;;     the default only does environments and C-c ' buffers -- and the 0.25s
;;     delay (default 1s) makes it follow the typing.
;; dvisvgm is the default converter and is what Fedora's TeX Live ships; it
;; needs Ghostscript support (`dvisvgm --version=yes' lists it) and Emacs
;; built with SVG, both true here.
;;
;; `org-latex-preview-appearance-options' is set with a fresh copy rather than
;; `plist-put' on the live value, which would edit the quoted default inside
;; org-latex-preview.el in place. The hook is guarded on the library existing,
;; so on Emacs's bundled Org 9.7 (Org-from-Git install failed or removed) this
;; section does nothing rather than erroring in every org buffer.
(setq org-latex-preview-mode-display-live t
      org-latex-preview-mode-update-delay 0.25)
(with-eval-after-load 'org-latex-preview
  (setq org-latex-preview-appearance-options
        (plist-put (copy-sequence org-latex-preview-appearance-options)
                   :page-width 0.8)))
(when (locate-library "org-latex-preview")
  (add-hook 'org-mode-hook #'org-latex-preview-mode))

;; --- Notes (org-roam) -------------------------------------------------------
;; Zettelkasten-style linked notes over org-mode. org itself ships with Emacs
;; (9.7.11 here), so only org-roam is installed; there is no org package to add.
;;
;; org-roam keeps a SQLite index of nodes and links, reached through EmacSQL.
;; EmacSQL picks its own backend (see `emacsql-sqlite-default-connection'):
;; built-in SQLite first, else the `sqlite3' dynamic module. Fedora's
;; emacs-pgtk 30.2 is built --with-sqlite3 (`sqlite-available-p' is t), so the
;; built-in backend (`emacsql-sqlite-builtin') is what gets used and no module
;; package is needed. The `sqlite3' module package used to be listed above for
;; builds without --with-sqlite3; it was dropped in 2026-10 once the rpm gained
;; it (its C build also failed here for want of sqlite3.h). EmacSQL has no
;; bundled-executable fallback any more, so on an Emacs built WITHOUT
;; --with-sqlite3 the `sqlite3' package must go back into the list above, or
;; org-roam dies at startup with "EmacSQL could not find or compile a back-end".
;; The knowledge base is the whole academic organization repo: every active
;; org file there carries a file-level ID and is an org-roam node. The db
;; lives inside the repo (dot-file, gitignored) so the index travels with it.
(setq org-roam-directory (expand-file-name "~/slimer"))
(setq org-roam-db-location (expand-file-name "~/slimer/.org-roam.db"))
;; Keep archived/binary trees out of the node list, mirroring the exclusions
;; org-config.el applies to `org-agenda-files'. Lock files (.#foo.org) too.
(setq org-roam-file-exclude-regexp '("archive/" "attachments/" "cv/" "\\.#"))
;; Suppress the v2 migration prompt: this is a fresh install, not a v1 upgrade.
(setq org-roam-v2-ack t)
;; Show each node's title, then its tags, in the completion list.
(setq org-roam-node-display-template
      (concat "${title:*} " (propertize "${tags:20}" 'face 'org-tag)))
;; ~/slimer/.dir-locals.el sets per-file org behavior (folding, logging,
;; property inheritance) for the whole notes repo. Those variables carry no
;; `safe-local-variable' predicate upstream, so visiting any note fires the
;; "values that may not be safe" prompt. Whitelist the exact value pairs here
;; instead of answering `!' in the prompt, which would grow the Custom-owned
;; block at the end of this file. Value pairs, not blanket trust: if the
;; .dir-locals.el changes, the prompt returns and the new value gets reviewed.
;; This must stay ahead of `org-roam-db-autosync-mode' below: enabling it runs
;; `org-roam-db-sync' synchronously, and `org-roam-with-file' calls
;; `hack-local-variables' on every note changed since the last sync. The Custom
;; block's copy of these pairs is no help, since it only runs at the end of
;; init, so a whitelist placed after the sync still prompts at startup whenever
;; a note was edited outside this Emacs (e.g. a git pull).
(dolist (pair '((org-startup-folded . content)
                (org-startup-indented . t)
                (org-log-done . time)
                (org-log-into-drawer . "LOGBOOK")
                (org-use-property-inheritance . t)))
  (add-to-list 'safe-local-variable-values pair))
(require 'org-roam)
;; Bundled modules: protocol capture, Graphviz graphs, daily notes, and ID-aware HTML export.
(require 'org-roam-protocol)
(require 'org-roam-graph)
(require 'org-roam-dailies)
(require 'org-roam-export)
;; `org-roam-directory' must exist before the database syncs against it.
(make-directory org-roam-directory t)
;; Keep the index live as notes are edited, rather than needing M-x org-roam-db-sync.
(org-roam-db-autosync-mode 1)
;; The `C-c n' prefix is org-roam's own documented convention.
(global-set-key (kbd "C-c n f") #'org-roam-node-find)
(global-set-key (kbd "C-c n i") #'org-roam-node-insert)
(global-set-key (kbd "C-c n c") #'org-roam-capture)
(global-set-key (kbd "C-c n l") #'org-roam-buffer-toggle)
;; Images and equation OCR. Keep downloaded images in Org's attachment store.
(require 'org-download)
(setq org-download-method 'attach)
(add-hook 'dired-mode-hook #'org-download-enable)
(require 'mathpix)
;; Credentials stay outside the versioned configuration.
(setq mathpix-app-id (or (getenv "MATHPIX_APP_ID") mathpix-app-id)
      mathpix-app-key (or (getenv "MATHPIX_APP_KEY") mathpix-app-key))
;; KDE's region selector is available on this desktop.
(when (executable-find "spectacle")
  (setq org-download-screenshot-method "spectacle -b -r -n -o %s"
        mathpix-screenshot-method "spectacle -b -r -n -o %s"))

;; Org sidebars: task overview and navigable outline tree, respectively.
(global-set-key (kbd "C-c n s") #'org-sidebar-toggle)
(global-set-key (kbd "C-c n t") #'org-sidebar-tree-toggle)

;; --- Calendar <-> org agenda -------------------------------------------------
;; The agenda itself is configured inside the org repo
;; (~/slimer/org-config.el: `org-agenda-files', capture templates, refile,
;; todo keywords) so it travels with the notes, not with this machine's Emacs.
;; Until now that file only loaded when loaded by hand, which was fine for
;; editing org files but useless for a calendar that should always know what
;; the agenda holds. Load it at startup when the repo is present; guarded so a
;; machine without the repo still boots (same policy as mu4e). org is already
;; loaded above (org-roam) and the file requires org-agenda itself, so the
;; real cost is just its recursive scan of the repo's org files.
(let ((org-repo-config (expand-file-name "~/slimer/org-config.el")))
  (when (file-readable-p org-repo-config)
    (load org-repo-config nil :nomessage)))
;; The agenda entry point, on the binding the org manual reserves for it.
(global-set-key (kbd "C-c a") #'org-agenda)

;; Wire M-x calendar and the agenda together in both directions, using the
;; org manual's own diary-sexp recipe rather than an external package:
;; - agenda -> calendar ships with org (`c' in an agenda jumps to the date's
;;   calendar); the mirror binding does not exist upstream, so `c' in the
;;   calendar below opens that day's agenda.
;; - diary -> agenda: `org-agenda-include-diary' folds diary entries into the
;;   agenda, and a holiday sexp in the diary file is what puts holiday names
;;   there (from `calendar-holidays' -- customize that list for local
;;   holidays). That sexp is *not* org's own `org-calendar-holiday': as of
;;   org 9.7 it reads `org-agenda-current-date', which only org-agenda binds.
;;   Reached the other way -- `d' or `M-x diary' from the calendar, where
;;   diary-lib binds `date' instead -- it hands nil to
;;   `calendar-check-holidays', which then builds the holiday list with
;;   `displayed-month' nil and fills *Warnings* with one "Bad holiday list
;;   item" per entry in `calendar-holidays'. `os-diary-holiday-entry' below
;;   takes whichever of the two is actually bound, so one diary file serves
;;   both directions.
;; - org -> calendar: the `org-diary' sexp lets `d' in the calendar list a
;;   date's org entries. No duplicates in the agenda: org-agenda binds
;;   `org-disable-agenda-to-diary' while it reads the diary, which switches
;;   `org-diary' off for that pass (verified against org-agenda.el).
;; Both sexps are nonmarking ("&", the manual's form) so calendar marking
;; never has to scan the org repo; holidays are marked from
;; `calendar-holidays' directly, hand-written diary lines (birthdays, ...)
;; mark themselves. The diary file is bootstrapped once if missing, like the
;; org-roam directory above -- it is data, not config, so it lives in
;; ~/.emacs.d rather than this repo.
(require 'calendar)
(defvar org-agenda-current-date)         ; org.el, bound only while the agenda runs
(defun os-diary-holiday-entry ()
  "Holiday names for the diary date being processed, or nil.
A drop-in for `org-calendar-holiday' that also works outside the
agenda: the org agenda binds `org-agenda-current-date', while
`diary-list-entries' binds the unprefixed `date'.  Both are read
through `boundp' rather than referenced directly, because neither
is globally special -- each owning file declares it for itself."
  (require 'holidays)
  ;; `date' first: diary-lib binds it for the day being listed in *both*
  ;; directions (org-agenda reaches the diary through `diary-list-entries'
  ;; too). `org-agenda-current-date' is only a fallback, because org-agenda
  ;; `setf's it globally and never clears it, so after one agenda run it
  ;; holds the last day of that run -- read first, it put that day's
  ;; holidays on every date the calendar or calfw asked about.
  (let* ((day (or (and (boundp 'date) (consp (symbol-value 'date))
                       (symbol-value 'date))
                  (and (boundp 'org-agenda-current-date) org-agenda-current-date)))
         (holidays (and (consp day) (calendar-check-holidays day))))
    (and holidays (mapconcat #'identity holidays "; "))))
(unless (file-exists-p diary-file)
  (with-temp-file diary-file
    (insert "&%%(os-diary-holiday-entry)\n&%%(org-diary)\n")))
(setq org-agenda-include-diary t)
;; The fancy diary display already names the day's holidays in its date header,
;; and org keeps that text as an entry -- with the sexp above it would list each
;; holiday twice. The sexp is the single source of holiday names.
(setq diary-show-holidays-flag nil)
;; England and Wales bank holidays, as `holiday-local-holidays'. The fixed
;; ones move to the next working day when they fall on a weekend: New Year's
;; Day to the Monday, Christmas Day and Boxing Day two days on (25 Sat -> Mon
;; 27, 25 Sun -> Tue 27 because Boxing Day already takes the Monday, 26 Sat ->
;; Mon 28, 26 Sun -> Tue 28). `holiday-sexp' evaluates its form with `year'
;; bound and expects a (M D Y) date back. Good Friday is left out here because
;; `holiday-christian-holidays' already lists it.
(defun os-uk-bank-holiday-substitute (year month day)
  "Date on which the bank holiday nominally on DAY MONTH YEAR is observed."
  (let* ((abs (calendar-absolute-from-gregorian (list month day year)))
         (dow (% abs 7)))                ; 0 = Sunday, 6 = Saturday
    (calendar-gregorian-from-absolute
     (cond ((= month 12) (if (memq dow '(0 6)) (+ abs 2) abs))
           ((= dow 6) (+ abs 2))
           ((= dow 0) (+ abs 1))
           (t abs)))))
(setq holiday-local-holidays
      '((holiday-sexp '(os-uk-bank-holiday-substitute year 1 1)
                      "New Year's Day (bank holiday)")
        (holiday-easter-etc 1 "Easter Monday (bank holiday)")
        (holiday-float 5 1 1 "Early May bank holiday")
        (holiday-float 5 1 -1 "Spring bank holiday")
        (holiday-float 8 1 -1 "Summer bank holiday")
        (holiday-sexp '(os-uk-bank-holiday-substitute year 12 25)
                      "Christmas Day (bank holiday)")
        (holiday-sexp '(os-uk-bank-holiday-substitute year 12 26)
                      "Boxing Day (bank holiday)")))
;; Emacs's stock `calendar-holidays' is the concatenation of the
;; `holiday-*-holidays' lists, Hebrew and Islamic ones included. Those two
;; have no bearing on this diary, so the list is rebuilt from the same parts
;; without them. Set inside `with-eval-after-load' because the default is
;; computed when holidays.el loads, and that happens lazily (the diary sexp
;; above requires it on first use), so an early `setq' would be overwritten.
(with-eval-after-load 'holidays
  (setq calendar-holidays
        (append holiday-general-holidays
                holiday-local-holidays
                holiday-other-holidays
                holiday-christian-holidays
                holiday-bahai-holidays
                holiday-oriental-holidays
                holiday-solar-holidays)))
(setq calendar-mark-holidays-flag t)
(setq calendar-mark-diary-entries-flag t)
(define-key calendar-mode-map (kbd "c") #'org-calendar-goto-agenda)

;; --- Month grid (calfw) ------------------------------------------------------
;; calfw is a calendar *view* framework: a month grid with entry text drawn
;; inside the day cells, which the built-in `calendar' cannot do -- it renders
;; bare day numbers and needs `d' or the agenda to say what is on a date. Both
;; stay: `calendar' remains the thing bound to date arithmetic, holidays and
;; the diary (`calendar-mode-map' above is untouched), calfw is the read-only
;; overview.
;;
;; Two sources are loaded, matching the two the section above wires together:
;;   calfw-org -- org agenda entries (`org-agenda-files', so it follows
;;                ~/slimer/org-config.el and its mid-session refresh advice);
;;   calfw-cal -- the diary file, which is where holidays and hand-written
;;                lines live.
;; `os-calfw-open' shows them in one grid rather than making a choice between
;; `calfw-org-open-calendar' and `calfw-cal-open-diary-calendar' -- those two
;; each open their own single-source buffer and are left available.
;;
;; calfw 2.0 renamed everything from the old `cfw:' prefix to `calfw-'; this
;; section uses the new names, so any recipe found online predating that
;; release needs `calfw-compat' (not loaded here) or translating.
;;
;; Nothing is `require'd at startup: all four entry points are autoloaded, and
;; calfw-org pulls in org-agenda, which is already loaded by org-config.el.
;; calfw draws holiday names into the day cells itself from `calendar-holidays'
;; -- and the diary source below already lists them through the holiday sexp in
;; the diary file, so each would appear twice. Same policy as
;; `diary-show-holidays-flag' above: the diary sexp is the one source.
(setq calfw-display-calendar-holidays nil)
(autoload 'calfw-open-calendar-buffer "calfw" nil t)
(autoload 'calfw-org-create-source "calfw-org")
(autoload 'calfw-cal-create-source "calfw-cal")
(defun os-calfw-org-events (begin end)
  "Collect Org events between BEGIN and END using the current agenda files."
  (when (fboundp 'organization-refresh-agenda-files)
    (organization-refresh-agenda-files))
  (calfw-org--schedule-period-to-calendar (org-agenda-files) begin end))

(defun os-calfw-open ()
  "Open a calfw month grid showing org agenda entries and diary entries."
  (interactive)
  (require 'calfw-org)
  (require 'calfw-cal)
  (calfw-open-calendar-buffer
   ;; Resolve files on every refresh: `calfw-org-create-source' captures
   ;; its file list once and does not run the advice on `org-agenda'.
   :contents-sources (list (make-calfw-source
                            :name "org" :color "SteelBlue"
                            :data #'os-calfw-org-events)
                          (calfw-cal-create-source "diary" "ForestGreen"))
   :view 'month
   :sorter #'calfw-org--schedule-sorter))
;; `C-c v' for *v*iew, not `C-c c': the org manual reserves that one for
;; `org-capture', and ~/slimer/org-config.el already defines the templates
;; it would run.
(global-set-key (kbd "C-c v") #'os-calfw-open)
;; The diary file carries `&%%(org-diary)' so that `d' in the calendar lists
;; org entries. calfw-cal reads that same file through `diary-list-entries',
;; so in the grid every org entry arrived twice: once from the org source and
;; once, relabelled "diary", from the diary source. Org's own agenda avoids
;; the same duplication by setting `org-disable-agenda-to-diary' while it
;; reads the diary, which makes `org-diary' contribute nothing; binding it
;; around calfw-cal's read gives the grid the same treatment and leaves `d' in
;; the calendar untouched.
(define-advice calfw-cal--schedule-period-to-calendar
    (:around (fn &rest args) os-calfw-cal-without-org)
  "Read the diary for calfw without the org entries `org-diary' would add."
  (let ((org-disable-agenda-to-diary t))
    (apply fn args)))

;; --- Bibliography, graph, and node queries ----------------------------------
;; Four things layered on org-roam, all from MELPA:
;;   citar + citar-org-roam -- a completion UI over the .bib for org-cite, with
;;                             org-roam nodes standing in as the note store;
;;   org-roam-bibtex        -- capture templates and attachment handling keyed
;;                             by citekey, plus `orb-insert-link';
;;   org-roam-ui            -- the node graph, served to a browser;
;;   org-roam-ql            -- a query language over the node database.
;;
;; This block deliberately sits after ~/slimer/org-config.el is loaded above.
;; That file owns the bibliography path -- it is what puts bibliography.bib on
;; `org-cite-global-bibliography', `bibtex-completion-bibliography', and
;; `citar-bibliography' -- because the bibliography travels with the notes repo
;; rather than with this machine. `org-roam-bibtex-mode' parses the .bib as it
;; turns on, so it has to find that path already set.

;; Hand org-cite's three processors to citar in place of the `basic' ones org
;; ships with: `C-c C-x @' then completes on authors and titles and marks which
;; keys already have a note or a PDF, and citations fontify in the buffer. No
;; `require' is needed -- citar's autoload file registers the processor inside a
;; `with-eval-after-load' on `oc', so citar itself loads only on first use.
(setq org-cite-insert-processor 'citar
      org-cite-follow-processor 'citar
      org-cite-activate-processor 'citar)

;; A reference note here is an org-roam node whose ROAM_REFS property holds the
;; citekey, not an entry in citar's own one-file-per-key store.
;; `citar-org-roam-mode' is what swaps citar's notes source over to org-roam, so
;; the "has a note" indicator in the citar UI is answered from the roam
;; database. Deferring it until citar loads is early enough: nothing consults
;; the notes source before that.
(with-eval-after-load 'citar
  (citar-org-roam-mode 1)
  ;; Where a newly captured reference note is born, relative to
  ;; `org-roam-directory'. The repo's convention is that a literature note
  ;; lives with the material it belongs to; this is only the landing spot, and
  ;; `C-c C-w' refiles it from there.
  (setq citar-org-roam-subdir "areas/research/readings"))

;; ORB writes the citekey into ROAM_REFS itself, and its default format is
;; org-ref's `cite:' link syntax. The repo cites with org-cite, so the property
;; has to carry a bare `@key' element instead; otherwise org-roam and org-cite
;; disagree about what a ref is and a note stops matching its BibTeX entry.
;; Setting the variable before the mode turns on is what makes it stick --
;; `defcustom' leaves an already-bound value alone.
(setq orb-roam-ref-format 'org-cite)
;; Autoloaded, so this call is also what loads ORB (and bibtex-completion with
;; it). Enabled eagerly rather than deferred because it hooks org-roam-capture,
;; which is reachable from `C-c n c' without citar ever being involved.
(org-roam-bibtex-mode 1)
;; On the overlap with citar-org-roam: `org-roam-bibtex-mode' also reaches for
;; citar's note handling, but only through `citar-open-note-function', which
;; citar 1.x retired in favour of the notes-source API and now leaves unbound.
;; ORB guards that assignment with `boundp' and so skips it -- citar-org-roam
;; keeps the notes source, and ORB contributes its captures, its attachment
;; handling, and `orb-insert-link'. Having both on is fine.

;; org-ref is installed for its BibTeX-side tooling, NOT as a citation system.
;; org-ref and org-cite are two complete, competing answers to citations in org:
;; org-ref has its own `cite:' links, its own export path and its own insert
;; commands, and this repo already answers all three with org-cite + citar
;; (processors set above; `orb-roam-ref-format' is pinned to `org-cite' so
;; ROAM_REFS stays `@key' rather than org-ref's `cite:key'). None of that
;; changes here -- org-ref installs no org-cite processor and hijacks nothing
;; unless one of its own insert commands is called, so the two coexist as long
;; as `cite:' links stay out of the notes.
;;
;; What it is actually here for is everything that happens *before* a citekey
;; exists: fetching a BibTeX entry from a DOI, arXiv id, ISBN or PubMed id
;; (`doi-utils-add-bibtex-entry-from-doi', `arxiv-add-bibtex-entry',
;; `isbn-to-bibtex', `pubmed-insert-bibtex-from-pmid'), normalising a pasted
;; entry (`org-ref-clean-bibtex-entry' -- key generation, field ordering,
;; non-ASCII replacement, DOI-derived URL), and pulling the PDF down next to
;; it. citar and ORB both read bibliography.bib; neither writes to it.
;;
;; Left autoloaded, like magit and the theme packs: org-ref pulls in citeproc,
;; ox-pandoc, request and avy, and `require'-ing it eagerly would also install
;; its `cite:' link types at startup for no gain. Every command named here is
;; autoloaded, so calling one loads the package. (Two of its optional files,
;; org-ref-helm.el and org-ref-ivy.el, fail to byte-compile on install because
;; helm and ivy aren't installed -- expected, and nothing loads them.)
;;
;; `bibtex-completion-bibliography' -- set by ~/slimer/org-config.el, same as
;; for citar -- is where these commands file new entries, so there is no
;; separate `org-ref-default-bibliography' to keep in sync.
(global-set-key (kbd "C-c n d") #'doi-utils-add-bibtex-entry-from-doi)
;; In a .bib buffer, upgrade bibtex-mode's own `C-c C-c' (`bibtex-clean-entry')
;; to org-ref's superset, and put the DOI-driven entry updater next to it.
(with-eval-after-load 'bibtex
  (define-key bibtex-mode-map (kbd "C-c C-c") #'org-ref-clean-bibtex-entry)
  (define-key bibtex-mode-map (kbd "C-c C-u") #'doi-utils-update-bibtex-entry-from-doi))

;; org-roam-ui serves the graph over a local websocket and opens it in the
;; browser. Its defaults already sync the Emacs theme, follow point, and redraw
;; on save, so there is nothing to set; it stays autoloaded, which keeps the
;; websocket and httpd servers from starting until the graph is first opened.

;; org-roam-ql queries the node database (`(and (tags "research") (todo))' and
;; the like) into an agenda-style buffer. Autoloaded; `org-roam-ql-ql' is a
;; separate package, not installed, that would additionally expose these
;; predicates to org-ql.

;; Keys continue org-roam's own `C-c n' prefix (f/i/c/l/s/t are bound above).
(global-set-key (kbd "C-c n b") #'orb-insert-link)
(global-set-key (kbd "C-c n r") #'citar-open-notes)
(global-set-key (kbd "C-c n g") #'org-roam-ui-open)
(global-set-key (kbd "C-c n q") #'org-roam-ql-search)

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

;; --- PostgreSQL -------------------------------------------------------------
;; pgmacs (Git, installed above) talks to PostgreSQL over the wire protocol via
;; pg-el -- no libpq, no psql needed. Deliberately *not* `require'd: its entry
;; points (`pgmacs', `pgmacs-open-string', `pgmacs-open-uri') are autoloaded,
;; and requiring it would drag pg/peg/widget in at startup for a client that is
;; used on demand. Nothing to configure here: connection details are
;; entered interactively (or passed as a string/URI to the open commands).

;; --- vterm ------------------------------------------------------------------
;; Fully-featured terminal emulator backed by a native module. The module is
;; compiled on first use and needs cmake + libtool installed on the system.
;; Keep it autoloaded rather than requiring it during init: when the module is
;; absent, vterm asks whether to compile it, and a minibuffer prompt during
;; startup can abort the whole initialization (notably for daemon sessions).
;; package.el has already installed vterm and registered its autoloads above.

;; --- ghostel ----------------------------------------------------------------
;; A second terminal, kept next to vterm rather than instead of it. Ghostel is
;; also a native module, but wraps libghostty-vt (the VT engine behind the
;; Ghostty terminal) rather than libvterm, which buys the protocols libvterm
;; does not speak: Kitty keyboard and graphics (images in the terminal),
;; synchronized output, OSC 8 hyperlinks and desktop notifications. vterm stays
;; because claude-code-ide and julia-repl are both built on it.
;;
;; Unlike vterm there is nothing to build: the module is a prebuilt binary
;; downloaded on first `M-x ghostel'. That download is still a prompt-shaped
;; first-run cost, so the same rule as vterm applies -- no `require' here, the
;; autoloads package.el registered are enough, and a daemon startup never
;; blocks on it.
;;
;; `C-c t' rather than the README's `C-x m': that is `compose-mail', which mu4e
;; territory below has a legitimate claim on.
(global-set-key (kbd "C-c t") #'ghostel)

;; --- claude-code-ide --------------------------------------------------------
;; Runs the Claude Code CLI inside a vterm buffer with IDE integration.
(require 'claude-code-ide)

;; --- codex-ide --------------------------------------------------------------
;; Pure-Emacs client for the Codex CLI (no vterm): syntax-highlighted output,
;; native diffs and in-buffer approval flows. `C-c C-;' opens its transient menu.
(require 'codex-ide)
(global-set-key (kbd "C-c C-;") #'codex-ide-menu)

;; Match the GUI font in code, tables, and command output; follow font changes.
(require 'face-remap)

(defun simon-codex-use-default-font ()
  "Use the GUI default face for fixed-width text in Codex buffers."
  (face-remap-set-base 'fixed-pitch 'default))

(add-hook 'codex-ide-session-mode-hook #'simon-codex-use-default-font)


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

;; The `time' and `battery' segments at the tail of the `main' modeline only
;; render when their underlying global modes are on; without these two lines
;; both segments are dead weight. Clock only -- the load average shown by
;; default is noise -- and the battery readout is wanted on this laptop.
(setq display-time-default-load-average nil)
(display-time-mode 1)
(display-battery-mode 1)

;; Live word count in prose buffers. The default mode list covers markdown,
;; org and gfm but not the TeX modes, where most long-form writing here
;; actually happens -- add them.
(setq doom-modeline-enable-word-count t)
(dolist (mode '(tex-mode latex-mode))
  (add-to-list 'doom-modeline-continuous-word-count-modes mode))

;; Buffer encoding is UTF-8 everywhere on this machine, so announcing it in
;; every buffer conveys nothing. `nondefault' shows the segment only when the
;; encoding is unusual -- exactly when it matters.
(setq doom-modeline-buffer-encoding 'nondefault)

;; line:column rather than line alone -- LSP diagnostics and compiler errors
;; address positions by column, so the modeline should speak the same language.
(column-number-mode 1)

;; Show file names as project-relative paths (abbreviated), e.g.
;; my-config-files/e/init.el, instead of the bare base name.
(setq doom-modeline-buffer-file-name-style 'truncate-with-project)

;; Always spell out error/warning counts in the check segment instead of only
;; tinting an icon (`auto', the default, drops the counts on narrow windows).
(setq doom-modeline-check 'full)

;; Keep a consistent minimum height in main and sidebar modelines.  The
;; `bar' segment supplies Doom's height strut as well as the vertical divider;
;; omitting it from main made Treemacs (which includes it) appear taller.
;; Use the plain divider rather than the buffer-position HUD.
(setq doom-modeline-height 28
      doom-modeline-hud nil)

;; Tux alone marks the host OS; the following bar separates it from buffer
;; information.  A 1.4 scale makes Tux prominent; the shared 28px strut
;; remains the minimum height for main and sidebar modelines.
(doom-modeline-def-segment os-tux
  (concat (doom-modeline-spc)
          (nerd-icons-flicon "nf-linux-tux" :height 1.4 :v-adjust 0.0)
          (doom-modeline-spc)))

;; Standard main segments with Tux prepended.  These lists follow
;; doom-modeline's defaults; re-sync them when upstream changes.
(doom-modeline-def-modeline 'main
  '(os-tux bar eldoc window-state workspace-name window-number modals matches follow buffer-info remote-host buffer-position word-count parrot selection-info)
  '(compilation objed-state misc-info project-name persp-name battery grip irc mu4e gnus github debug repl lsp minor-modes input-method indent-info buffer-encoding major-mode process vcs check time))

(minions-mode 1)
(doom-modeline-mode 1)

;; --- Themes (ef-themes + leuven + solarized + doom-themes + foxglove) --------
;; Only one theme is ever active, and `ef-elea-light' at the end of this section
;; is it. `leuven' -- Fabrice Niessen's light theme, the one the ef-themes org
;; styling below is modelled on -- and `leuven-dark' ship *with Emacs*
;; (etc/themes/), so they need no package, no entry in `required-packages' and
;; nothing installed, the built-in themes directory already being the `t'
;; element of `custom-theme-load-path'. leuven-dark's mode-line is unreadable
;; under doom-modeline as shipped; `os-leuven-dark-mode-line-faces' below repairs
;; it. leuven-dark, the previous active theme, is still fully set up for a switch
;; back: the `os-leuven-dark-*' hooks each test the theme's name, so they sit
;; idle on `enable-theme-functions' under any other theme.
;;
;; The four installed theme *packs* are here to switch to with M-x load-theme,
;; so they are deliberately not `require'd or loaded for their themes' sake: a
;; pack costs nothing until a theme from it is loaded, and each package's
;; autoloads already add its directory to `custom-theme-load-path', which is all
;; `load-theme' and `custom-available-themes' need to find them.
;;
;; Themes stack rather than replace, so `load-theme' on top of a live theme
;; leaves the old one's faces showing through wherever the new one is silent.
;; M-x disable-theme (or ef-themes' own commands, which do this for you) first.
;;
;;   ef-themes        -- Protesilaos' legible light/dark pairs (13 x 2); the
;;                       main pack. M-x ef-themes-select, or ef-themes-toggle
;;                       for the pair named in `ef-themes-to-toggle' below; the
;;                       `require' is what makes that pair, the heading styles
;;                       and the palette overrides below all take effect
;;                       whenever an ef theme is loaded.
;;   solarized-theme  -- bbatsov's Emacs port of Ethan Schoonover's Solarized;
;;                       13 variants (solarized-light/-dark, the -high-contrast
;;                       and -selenized-* sets, plus gruvbox/wombat/zenburn).
;;   doom-themes      -- the Doom Emacs collection, 77 themes (doom-one,
;;                       doom-nord, doom-gruvbox, doom-tokyo-night, ...).
;;                       Its optional extras (`doom-themes-visual-bell-config',
;;                       `doom-themes-org-config') need an explicit
;;                       (require 'doom-themes) and are not enabled here.
;;   foxglove-themes  -- Vegas Harmon's low-contrast, journal-like themes,
;;                       built to stay legible on e-ink: `foxglove' (Linen
;;                       paper), `foxglove-vellum' (warmer), `foxglove-mono'
;;                       (exact greys only), each with a -dark twin. Installed
;;                       from GitLab with `package-vc-install' above. Like the
;;                       ef-themes they are Modus derivatives, so the Modus
;;                       settings in the next section reach them too -- see
;;                       the note after the palette overrides. Their own
;;                       options are in M-x customize-group foxglove-themes.
(require 'ef-themes)
(setq ef-themes-to-toggle '(ef-elea-light ef-elea-dark))

;; --- Giving the ef-themes leuven's org typography ----------------------------
;; Out of the box the ef-themes render every org headline at the body text's
;; size and draw nothing around it, so an org buffer is a wall of same-sized
;; lines. leuven answers that in two ways: it scales the document title (1.8)
;; and level-1 headlines (1.3) up, and it rules levels 1-2 off with a horizontal
;; line above the headline (`:overline'), level 1 also sitting on a tinted band.
;; Both are reproduced below, for every ef theme at once.
;;
;; The lever is that since ef-themes 2.0 the pack no longer defines its own
;; faces: it derives from the modus-themes, and `ef-themes.el' calls
;; `ef-themes-define-compatibility-aliases' to make `ef-themes-headings',
;; `ef-themes-common-palette-overrides' and friends plain `defvaralias'es for
;; the `modus-themes-*' options. So these are settings, not theme edits -- no
;; ef-*-theme.el file is touched (they are package files and would be
;; overwritten on the next update anyway), and all 38 ef themes, present and
;; future, pick them up. leuven reads neither variable, so it stays as it is.
;;
;; `ef-themes-headings' is an alist of (LEVEL . PROPERTIES); a float in
;; PROPERTIES is a height multiplier of the `default' face. Level 0 is the
;; `#+title' line, 1-8 the headlines, `t' the fallback, and the two `agenda-*'
;; keys are the agenda's own headings. Where leuven leaves levels 2-8 flat at
;; 1.0 this tapers 2 and 3 slightly -- same intent, gentler, because the ef
;; palettes already colour-code each level. leuven scales `agenda-date' to 1.6
;; as well; at 1.6 every date line in a week view shouts, so it is 1.3 here.
;; The title is 1.6 rather than leuven's 1.8: at 1.8 over a 13pt default it
;; overpowers the level-1 headlines it sits above.
(setq ef-themes-headings
      '((0 . (1.6))                     ; #+title, as leuven's org-document-title
        (1 . (1.3))
        (2 . (1.15))
        (3 . (1.05))
        (agenda-date . (1.3))
        (agenda-structure . (variable-pitch 1.6))
        (t . (1.0))))

;; The rules and the level-1 band. The modus heading faces already read
;; `bg-heading-N', `fg-heading-N' and `overline-heading-N' out of the palette --
;; the backgrounds and overlines are `unspecified' in every ef theme, which is
;; why nothing shows -- so a palette override is all this needs: no
;; `custom-set-faces', no post-load hook, nothing to undo when the theme is
;; disabled. Point them at *semantic* names rather than hex, which is what makes
;; one setting right for all 38 themes: `bg-blue-subtle' resolves to #c9d8f3 in
;; ef-elea-light and to #26486c in ef-elea-dark, so the band stays a light-on-
;; dark or dark-on-light blue either way rather than a fixed colour that only
;; works in one of them. `fg-heading-1' normally maps to `rainbow-1' (a dusty
;; red in elea); `blue-cooler' (#162f8f in elea-light) is the darkest blue in
;; the palette, which is what holds up against the pale band behind it. Only
;; level 1 gets the band; leuven tints level 2 too, but stacked bands muddy the
;; darker ef palettes, so level 2 keeps the rule alone.
(setq ef-themes-common-palette-overrides
      '((bg-heading-1 bg-blue-subtle)
        (fg-heading-1 blue-cooler)
        (overline-heading-1 border)
        (overline-heading-2 border)))

;; The catch with "every ef theme at once": both variables above are really
;; `modus-themes-headings' and `modus-themes-common-palette-overrides', so they
;; reach every Modus *derivative*, foxglove included. The heading sizes are
;; welcome there -- foxglove leaves sizing to `modus-themes-headings' by
;; design, so the leuven scale carries over unchanged. The palette overrides
;; are not: Modus appends the common overrides after a derivative's own, and
;; both outrank the theme's palette, so under foxglove level 1 would turn into
;; lapis on a blue band instead of foxglove's body-ink heading on its grey
;; `bg-dim' band. `foxglove-themes-palette-overrides' comes first in that
;; chain, so restating foxglove's own values for the four entries there puts
;; them back. These are the values for its default heading styles (level 1
;; `band', level 2 `rule'); if `foxglove-themes-heading-1' or `-2' is changed,
;; drop the matching lines here or they will pin the old style's colours.
(setq foxglove-themes-palette-overrides
      '((bg-heading-1 bg-dim)
        (fg-heading-1 fg-main)
        (overline-heading-1 fox-rule)
        (overline-heading-2 border)))

;; Without this the overline stops where the headline text stops, which reads as
;; a dash rather than a rule; org only extends heading faces to the window edge
;; when told to. Global org setting, so it applies under leuven as well -- which
;; is what leuven's own documentation asks for in any case.
(setq org-fontify-whole-heading-line t)

;; --- The org file header block ----------------------------------------------
;; Every org-roam note opens with the same three-part block, and none of it is
;; readable as *structure* in a stock ef theme -- the drawer, the title and the
;; tag lines are all one shade of grey metadata:
;;
;;     :PROPERTIES:  :ID: ...  :END:     <- red band, `bg-red-subtle'  (#f0c6bf)
;;     #+title:  #+filetags:  #+startup: <- purple, `bg-magenta-subtle' (#edd2f0)
;;     #+options:  #+property:  ...         (every keyword in the block below)
;;
;; The asymmetry is deliberate: the drawer is banded whole, keyword and value
;; alike, because it is boilerplate to skip over -- one solid block the eye can
;; slide past. The `#+' lines carry content worth reading, so only the keyword
;; is tinted and the title, the tag list and the rest of the values are left on
;; the plain background.
;;
;; Both are the `-subtle' member of their pair, which is the palest each colour
;; gets in the ef palettes: the `-intense' alternatives (#ff8f88, #df9fff) are
;; saturated enough to read as a warning rather than as a header. Do not reach
;; for the `-nuanced' names to go lighter still -- they are inherited from
;; modus' fallback palette rather than defined by the ef themes, so they do not
;; track the theme (`bg-magenta-nuanced' is *darker* than `-subtle' in
;; ef-elea-light, not lighter).
;;
;; Unlike the headings above, these faces carry no palette hook: modus defines
;; org-drawer, org-property-value, org-document-info-keyword and the rest with a
;; foreground only, so a `bg-*' override has nothing to attach to and the
;; backgrounds have to be set on the faces themselves.
;;
;; Which is why this runs from `enable-theme-functions' rather than
;; `ef-themes-post-load-hook': the latter only fires from ef-themes' own
;; commands, so a plain M-x load-theme would silently skip it. The abstract hook
;; fires on every `enable-theme', whatever route got there. Two further details
;; make this revert cleanly instead of leaking:
;;
;;   - `custom-theme-set-faces' attributes the faces *to the ef theme* rather
;;     than to the user, so `disable-theme' takes them away again; plain
;;     `custom-set-faces' would outrank whatever theme was loaded next and would
;;     follow you into leuven.
;;   - colours come from `ef-themes-get-color-value', not from the
;;     `ef-themes-with-colors' macro. The macro `eval's its body dynamically, so
;;     the lexical THEME argument of a function like this one is not visible
;;     inside it -- the error is swallowed and the faces silently do not change.
;;   - the `custom-theme-recalc-face' sweep at the end is load-bearing, and its
;;     absence fails in a way designed to waste an afternoon. `enable-theme'
;;     recalculates faces from the snapshot of `theme-settings' it takes
;;     *before* running `enable-theme-functions', so faces this hook adds during
;;     that hook are recorded but never applied to a frame that already exists
;;     -- which on a normal GUI startup is every frame. New frames build their
;;     faces from the recorded specs and so look perfectly correct, meaning the
;;     bug is invisible to any test that makes a frame to inspect. See the NOW
;;     argument in `custom-theme-set-faces': "the caller is responsible for
;;     making the settings take effect later".
;;
;; `:extend t' is what makes each of these a band rather than a highlight behind
;; the text: it carries the background past the end of line to the window edge,
;; matching the headline rules above. `org-document-title' must restate its
;; `:inherit' because setting a face for a theme replaces that theme's whole
;; spec for it -- dropping the inherit would cost the 1.6 height set above.
(defun os-ef-themes-org-header-faces (theme)
  "Band the org header block for THEME when it is one of the ef-themes.
Added to `enable-theme-functions'; a no-op for every other theme."
  (when (string-prefix-p "ef-" (symbol-name theme))
    (let* ((properties (ef-themes-get-color-value 'bg-red-subtle nil theme))
           (metadata (ef-themes-get-color-value 'bg-magenta-subtle nil theme))
           (spec '((class color) (min-colors 256)))
           (faces
            `(;; The :PROPERTIES: ... :END: drawer: the drawer delimiters, the
              ;; :KEY: of each line, and the value after it -- three faces for
              ;; one band.
              (org-drawer ((,spec :inherit modus-themes-fixed-pitch
                                  :background ,properties :extend t)))
              (org-special-keyword ((,spec :inherit modus-themes-fixed-pitch
                                           :background ,properties :extend t)))
              (org-property-value ((,spec :inherit modus-themes-fixed-pitch
                                          :background ,properties :extend t)))
              ;; #+title:/#+subtitle:/#+author:/#+email:/#+date: -- org splits
              ;; each of those into the keyword (org-document-info-keyword) and
              ;; the value (org-document-title for the title,
              ;; org-document-info for the rest). Only the keyword is listed
              ;; here: leaving the two value faces alone is what keeps the
              ;; title and the tag list themselves un-tinted, and it leaves
              ;; them on the theme's own specs, so `org-document-title' keeps
              ;; its 1.6 height with nothing to restate. No `:extend' either --
              ;; the value follows on the same line, so there is no end-of-line
              ;; for a background to run past.
              (org-document-info-keyword ((,spec :inherit modus-themes-fixed-pitch
                                                 :background ,metadata))))))
      (apply #'custom-theme-set-faces theme faces)
      (mapc (lambda (entry) (custom-theme-recalc-face (car entry))) faces))))

(add-hook 'enable-theme-functions #'os-ef-themes-org-header-faces)

;; --- A dark mode-line for leuven-dark -----------------------------------------
;; leuven-dark is a hue-rotated leuven, and it rotated everything except the
;; mode-line, which stays a light tan bar (#cfa161) with dark text. Every
;; *other* colour in the theme is tuned for the dark #25202a buffer background:
;; `success' is #ff01ff (magenta), `warning' #065aff, `error' #06ffff. doom-
;; modeline's segments inherit those three (`doom-modeline-info' -> success for
;; the VCS branch, the full battery, LSP ...), and nerd-icons' fixed icon colours
;; are likewise picked for dark backgrounds -- so on the tan bar every coloured
;; element sat at 1.1-2.3:1 contrast: magenta icons on orange, unreadable.
;;
;; Recolouring the dozens of doom-modeline faces dark would fight both theme
;; and icon pack, so the bar comes to them instead: the active mode-line takes
;; leuven-dark's own `highlight' brown (#3c312a), on which the theme's success/
;; error/keyword colours reach 4-12:1, with the tan kept as a 1px box so the
;; leuven accent and the active/inactive cue survive. The inactive bar drops to
;; the buffer background. Three things follow from the text turning light:
;;   - `mode-line-buffer-id'/`mode-line-emphasis' were #25202a (dark on tan)
;;     and must flip to white, or the buffer name vanishes;
;;   - `warning' blue (#065aff) is 2.4:1 even here, and only 3.0:1 in
;;     leuven-dark's own buffers, so `warning' itself is lifted to #6f8cff --
;;     the same blue as slot 4 of the leuven-dark Ghostty theme -- and with it
;;     `compilation-mode-line-run' (doom-modeline's LSP-running face) and
;;     `mode-line-highlight' (hover), which used the same blue.
;;   - every face listed must be one leuven-dark *already* styles. For a theme
;;     other than `user', `custom-theme-set-faces' only records a new face in
;;     `theme-settings' (`custom--inhibit-theme-enable' is `apply-only-user'
;;     outside `load-theme'); it never reaches the face, so the recalc below
;;     finds nothing. That is why `warning' is lifted rather than
;;     `doom-modeline-warning', which leuven-dark does not mention: an entry
;;     for it here is silently dropped.
;;   - only this one theme is touched: the guard is an exact name match, and
;;     the faces are attributed to leuven-dark with `custom-theme-set-faces',
;;     so `disable-theme' reverts them. The `custom-theme-recalc-face' sweep is
;;     load-bearing for the reason given above `os-ef-themes-org-header-faces'.
(defun os-leuven-dark-mode-line-faces (theme)
  "Give THEME a dark, legible mode-line when it is `leuven-dark'.
Added to `enable-theme-functions'; a no-op for every other theme."
  (when (eq theme 'leuven-dark)
    (let* ((spec '((class color) (min-colors 89)))
           (faces
            `((mode-line ((,spec :box (:line-width 1 :color "#cfa161")
                                 :foreground "#cfccd2" :background "#3c312a")))
              (mode-line-inactive ((,spec :box (:line-width 1 :color "#3e3944")
                                          :foreground "#848088"
                                          :background "#25202a")))
              (mode-line-buffer-id ((,spec :weight bold :foreground "#ffffff")))
              (mode-line-emphasis ((,spec :weight bold :foreground "#ffffff")))
              (mode-line-highlight ((,spec :foreground "#6f8cff")))
              (warning ((,spec :weight bold :foreground "#6f8cff")))
              (compilation-mode-line-run ((,spec :weight bold
                                                 :foreground "#6f8cff"))))))
      (apply #'custom-theme-set-faces theme faces)
      (mapc (lambda (entry) (custom-theme-recalc-face (car entry))) faces))))

(add-hook 'enable-theme-functions #'os-leuven-dark-mode-line-faces)

;; Apply theme faces *now*, including faces the theme never styled. Outside
;; `load-theme', `custom-theme-set-faces' only records a face the theme does
;; not already style in the theme's `theme-settings' and never puts it on the
;; face (`custom--inhibit-theme-enable' is `apply-only-user' there) -- the
;; trap the mode-line note above describes, which is why that function lifts
;; `warning' rather than `doom-modeline-warning'. So after recording each
;; face, this does by hand what `enable-theme' would have done -- push the
;; spec onto the face's `theme-face' list under THEME -- and recalculates.
;; The record in `theme-settings' is what lets `disable-theme' take it off
;; again; binding `custom--inhibit-theme-enable' instead would also set
;; `saved-face', which M-x customize would later write into the Custom
;; block. Harmless for faces the theme does style. The recalc is needed for
;; those too, for the reason given above `os-ef-themes-org-header-faces'.
(defun os-custom-theme-apply-faces (theme faces)
  "Give THEME the face specs FACES and apply them to existing frames.
FACES is a list of entries as for `custom-theme-set-faces'.  Unlike that
function alone, this also reaches faces THEME did not style before."
  (apply #'custom-theme-set-faces theme faces)
  (dolist (entry faces)
    (let ((face (car entry)))
      (put face 'theme-face
           (cons (list theme (cadr entry))
                 (assq-delete-all theme (copy-sequence
                                         (get face 'theme-face)))))
      (custom-theme-recalc-face face))))

;; --- Org TODO keywords and headings for leuven-dark -------------------------
;; leuven's `org-todo' is a red box; the hue rotation turned it into dark teal
;; (#2c5462 on #253743, about 1.3:1), so open keywords were the least visible
;; thing on a heading instead of the most. Each task status now gets its own
;; filled chip -- dark #25202a text on a colour from the setup's palette --
;; so a status reads at a glance, in a heading and in the agenda (which draws
;; keywords with the same faces):
;;   TODO       yellow #ffff0b    `org-todo'         14.8:1
;;   NEXT       LightSkyBlue      `os-org-todo-next'  9.3:1  (the level-1 band's)
;;   WAIT       orange #ff9029    `os-org-todo-wait'  7.0:1  (blocked on others)
;;   HOLD       pink #ff9bff      `os-org-todo-hold'  8.6:1  (parked)
;;   DONE       SeaGreen3         `org-done'          7.8:1  (the cursor's)
;;   CANCELLED  grey #848088, struck through   `os-org-todo-cancelled'  4.1:1
;; The keywords are org-config.el's `org-todo-keywords'; the faces are mapped
;; here through `org-todo-keyword-faces' (which org-config.el does not set),
;; because they are a theme matter. The four `os-org-todo-*' faces default to
;; inheriting `org-todo' / `org-done', so under any other theme every status
;; simply looks like that theme's own TODO or DONE -- only leuven-dark gives
;; them colours, below. Add a line to both lists when a keyword is added.
;;
;; A filled chip is the one shape nothing else in leuven-dark uses at that
;; brightness. (Yellow text on a dark yellow tint was tried first and read as
;; just another coloured word.) The box is the background colour, an edge
;; that only shows where a chip sits on something bright, such as the
;; level-1 band.
;;
;; Finished items still recede, by *style* rather than dimness. leuven-dark
;; draws a DONE heading's text (`org-headline-done') in #57525c, tuned to fade
;; into the plain background and 1.1-1.4:1 on a coloured band -- unreadable.
;; It is now a light grey #c4c0c8 in italics (3.0:1 on the level-1 band, 8.9
;; on the plain background), plainly not the white of an open heading.
;;
;; Each chip colour is the *foreground* under `:inverse-video', not a background.
;; `hl-line' (on in every text-mode buffer) is an overlay, and overlay faces
;; win over the text-property face org puts on the keyword: on the cursor's
;; line its #2d2058 background replaced the yellow, leaving dark text on dark
;; -- the chip vanished exactly where you were looking. With inverse video the
;; overlay's background only lands in the swapped-in *text* slot, so the chip
;; keeps its colour on every line, its text #25202a off the cursor line and
;; #2d2058 on it; the region behaves the same way.
;;
;; Headings 1-3 are restyled. leuven-dark's own bands are the hue rotation of
;; leuven's pale grey/blue/green: #322d37, #3d2a2d, #332038 -- all within
;; 1.2:1 of the #25202a background, so they read as one dark bluish grey and
;; the outline has no visible shape. Now only level 1 is a band; levels 2-3
;; are coloured text on the plain background, so the top level stands apart
;; and the levels below it read as a quieter, colour-coded outline:
;;   1  band: cyan #06ffff mixed 35% into the background = #1a6e75, white
;;      text (5.9:1), overline rule in the undiluted #06ffff
;;   2  yellow text #ffff0b (14.8:1), leuven-dark's `font-lock-keyword-face'
;;   3  teal text #06c8cf (7.7:1), the teal of leuven-dark's js2-error box
;;
;; #06ffff is leuven-dark's own cyan (its shipped `error'), and the colour of
;; vertico's match patches below, so the top of the outline and "what you
;; searched for" share one hue. The band is "translucent" -- the full colour
;; mixed into the background, the nearest a face gets to transparency --
;; because it must carry light text: `hl-line' is an overlay, and its
;; background replaces the band's on the cursor line, so a band with dark
;; text would vanish there. (Full-strength cyan, too light for white text,
;; needed the TODO chip's `:inverse-video' trick, which also inverted tags and
;; links into patches.) On the band the TODO chip is 5.5:1 and the italic
;; DONE grey 3.3:1. Level-2 yellow text shares its colour with the TODO chip,
;; which stays distinct as a filled chip with dark text. Earlier rounds tried
;; green, wine, ochre, pink, yellow, orange, sky blue, bright blue,
;; LightSkyBlue and full-strength cyan.
;; Levels 4-8 keep leuven-dark's coloured text.
;;
;; Setting a theme face replaces the theme's whole spec for it, so level 1
;; restates its height through leuven-dark's own `leuven-dark-scale-font' --
;; 1.3, or 1.0 when `leuven-dark-scale-outline-headlines' is nil.
(defface os-org-todo-next '((t :inherit org-todo))
  "Face for the NEXT keyword; see `org-todo-keyword-faces'.")
(defface os-org-todo-wait '((t :inherit org-todo))
  "Face for the WAIT keyword; see `org-todo-keyword-faces'.")
(defface os-org-todo-hold '((t :inherit org-todo))
  "Face for the HOLD keyword; see `org-todo-keyword-faces'.")
(defface os-org-todo-cancelled '((t :inherit org-done))
  "Face for the CANCELLED keyword; see `org-todo-keyword-faces'.")

(setq org-todo-keyword-faces
      '(("NEXT" . os-org-todo-next)
        ("WAIT" . os-org-todo-wait)
        ("HOLD" . os-org-todo-hold)
        ("CANCELLED" . os-org-todo-cancelled)))

(defun os-leuven-dark-org-faces (theme)
  "Give org TODO keywords and headings stronger faces under `leuven-dark'.
THEME is the theme just enabled.  Added to `enable-theme-functions';
a no-op for every other theme."
  (when (eq theme 'leuven-dark)
    (let* ((spec '((class color) (min-colors 89)))
           (chip (lambda (colour &rest more)
                   `((,spec :weight bold :box (:line-width 1 :color "#25202a")
                            :foreground ,colour :background "#25202a"
                            :inverse-video t ,@more))))
           (faces
            `((org-todo ,(funcall chip "#ffff0b"))
              (os-org-todo-next ,(funcall chip "#87cefa"))
              (os-org-todo-wait ,(funcall chip "#ff9029"))
              (os-org-todo-hold ,(funcall chip "#ff9bff"))
              (org-done ,(funcall chip "#43cd80"))
              (os-org-todo-cancelled ,(funcall chip "#848088"
                                               :strike-through t))
              (org-headline-done ((,spec :height 1.0 :weight normal
                                         :slant italic :foreground "#c4c0c8")))
              (org-level-1 ((,spec ,@(leuven-dark-scale-font
                                      leuven-dark-scale-outline-headlines 1.3)
                                   :weight bold :overline "#06ffff"
                                   :foreground "#ffffff" :background "#1a6e75"
                                   :extend t)))
              (org-level-2 ((,spec :height 1.0 :weight bold
                                   :foreground "#ffff0b")))
              (org-level-3 ((,spec :height 1.0 :weight bold
                                   :foreground "#06c8cf"))))))
      (os-custom-theme-apply-faces theme faces))))

(add-hook 'enable-theme-functions #'os-leuven-dark-org-faces)

;; --- Comments and tags under leuven-dark --------------------------------------
;; leuven-dark's comments (#767283, 3.4:1) and org tags (#6a6065, 2.6:1) are
;; dimmed past legibility. Org's @@backend:...@@ export snippets show both at
;; once -- the `@@' in `font-lock-comment-face', the backend name matched as a
;; tag -- so a `@@comment: ...@@' note was the darkest text on the page.
;; Comments take the lighter grey leuven-dark's own source suggests, in a
;; trailing `; #9a969e' beside both comment faces (5.5:1; still well below
;; body text's 10:1, so comments recede). This is global: code comments in
;; every mode change with it. Tags take #a9a5ad (6.6:1) and keep their own
;; #25202a background, which is what keeps them readable as dark chips on
;; the level-1 heading band. All four faces are ones leuven-dark styles, so
;; plain `custom-theme-set-faces' reaches them.
(defun os-leuven-dark-comment-faces (theme)
  "Lighten comments and org tags when THEME is `leuven-dark'.
Added to `enable-theme-functions'; a no-op for every other theme."
  (when (eq theme 'leuven-dark)
    (let* ((spec '((class color) (min-colors 89)))
           (faces
            `((font-lock-comment-face ((,spec :slant italic
                                              :foreground "#9a969e")))
              (font-lock-comment-delimiter-face ((,spec :foreground "#9a969e")))
              (org-tag ((,spec :weight normal :slant italic
                               :foreground "#a9a5ad" :background "#25202a"))))))
      (apply #'custom-theme-set-faces theme faces)
      (mapc (lambda (entry) (custom-theme-recalc-face (car entry))) faces))))

(add-hook 'enable-theme-functions #'os-leuven-dark-comment-faces)

;; --- The cursor under leuven-dark ---------------------------------------------
;; leuven-dark's cursor is the orange-red #e1420b, a near neighbour of the
;; burnt-orange region and of the orange link text, so it got lost exactly
;; where it mattered. It takes SeaGreen3, #43cd80 -- the same colour in Emacs'
;; X11 names and in LaTeX's xcolor `x11names' (.264, .804, .5), so it matches
;; documents that use it -- which no other face in this setup uses: 7.8:1 on
;; the background, 7.0:1 on `hl-line', and the glyph drawn under a box cursor
;; (in the background colour) stays 7.8:1. The 2.6:1 on the level-1 heading
;; band is the one weak spot. `cursor' is a face leuven-dark styles, so plain
;; `custom-theme-set-faces' reaches it.
(defun os-leuven-dark-cursor-face (theme)
  "Make the cursor SeaGreen3 when THEME is `leuven-dark'.
Added to `enable-theme-functions'; a no-op for every other theme."
  (when (eq theme 'leuven-dark)
    (custom-theme-set-faces
     theme '(cursor ((((class color) (min-colors 89)) :background "#43cd80"))))
    (custom-theme-recalc-face 'cursor)))

(add-hook 'enable-theme-functions #'os-leuven-dark-cursor-face)

;; --- The minibuffer under leuven-dark: vertico and the prompt ----------------
;; `vertico-current' inherits `highlight', which leuven-dark sets to #3c312a --
;; 1.3:1 against the #25202a background, so the selected candidate was a
;; barely-darker smudge. It becomes a yellow bar instead, the keyword yellow
;; #ffff0b of the TODO chip and the level-3 band, with dark text (~15:1).
;; (Burnt orange #752c0b came first, and read as brown.) Only the face vertico
;; owns changes -- `highlight' itself also drives mouse hover and LSP symbol
;; highlighting, which should stay quiet.
;;
;; The yellow is again a foreground under `:inverse-video', but here for the
;; candidate's *other* faces rather than for `hl-line'. Vertico appends
;; `vertico-current' beneath the faces already on the candidate, so orderless'
;; match letters and marginalia's annotations keep their own light
;; foregrounds -- 1.4-2.3:1 on a plain yellow background. Under inverse video
;; each of those foregrounds becomes the background of its own stretch, with
;; the dark #25202a as text: the bar turns into yellow with coloured match
;; patches and a pale annotation patch, every piece dark-on-bright.
;;
;; Those match patches are therefore only as bright as the match faces'
;; foregrounds, and the defaults were pastel: `completions-common-part' (the
;; prefix a `basic'-style match covers -- the whole file name in `find-file')
;; is "lightblue", a washed-out patch beside the yellow. The match faces take
;; vivid leuven-dark colours instead: cyan #06ffff for the common part (and
;; bold, like orderless' own), then cyan / pink #ff9bff / green #78ff7c /
;; orange #ff9029 for orderless' four components. As patches they carry dark
;; text at 7.0-12.7:1 and stand off the yellow by hue (nothing is brighter
;; than yellow, so it cannot be by lightness); on every other candidate they
;; are the same colours as text on the dark background, 7.0-12.7:1 too.
;;
;; Marginalia's file permissions (`-rw-r--r--') colour each letter by kind
;; and every `-' with `marginalia-file-priv-no', which inherits `shadow'
;; (#848088, 4.1:1) -- the dashes were the dimmest thing in the column, and
;; on the yellow bar a dull grey patch. They take the light grey #c4c0c8 of
;; DONE headlines instead (8.9:1 as text, and as a patch with dark text);
;; `shadow' itself is left alone.
;;
;; The prompt (`minibuffer-prompt', and its `-noticeable-' twin that
;; leuven-dark styles identically) was white on the saturated blue #0628ff,
;; the loudest thing in the minibuffer. It takes SeaGreen3 #43cd80, the
;; cursor's colour (see `os-leuven-dark-cursor-face'), at full strength with
;; dark #25202a text (7.8:1) -- white would be ~2:1 on it. Dark text on a
;; plain background is safe here, unlike on the heading bands: the minibuffer
;; has no `hl-line' to replace it. (Teal and a translucent pink came first.)
;;
;; leuven-dark styles neither `vertico-current' nor the match faces, so this
;; goes through `os-custom-theme-apply-faces' rather than plain
;; `custom-theme-set-faces'. The orderless faces are set even before
;; orderless loads; their theme spec is waiting when its `defface' runs.
(defun os-leuven-dark-minibuffer-faces (theme)
  "Restyle vertico's current candidate and the prompt under `leuven-dark'.
THEME is the theme just enabled.  Added to `enable-theme-functions';
a no-op for every other theme."
  (when (eq theme 'leuven-dark)
    (let* ((spec '((class color) (min-colors 89)))
           (prompt `((,spec :weight bold :foreground "#25202a"
                            :background "#43cd80")))
           (faces `((vertico-current ((,spec :foreground "#ffff0b"
                                             :background "#25202a"
                                             :inverse-video t)))
                    (minibuffer-prompt ,prompt)
                    (minibuffer-noticeable-prompt ,prompt)
                    (completions-common-part ((,spec :weight bold
                                                     :foreground "#06ffff")))
                    (orderless-match-face-0 ((,spec :weight bold
                                                    :foreground "#06ffff")))
                    (orderless-match-face-1 ((,spec :weight bold
                                                    :foreground "#ff9bff")))
                    (orderless-match-face-2 ((,spec :weight bold
                                                    :foreground "#78ff7c")))
                    (orderless-match-face-3 ((,spec :weight bold
                                                    :foreground "#ff9029")))
                    (marginalia-file-priv-no ((,spec :foreground "#c4c0c8"))))))
      (os-custom-theme-apply-faces theme faces))))

(add-hook 'enable-theme-functions #'os-leuven-dark-minibuffer-faces)

;; org hands only five keywords to the document faces --
;; `org-fontify-meta-lines-and-blocks-1' special-cases title/subtitle/author/
;; email/date -- and drops every other `#+' line through to `org-meta-line'. So
;; #+startup:, #+filetags:, #+options:, #+property:, #+category: and the rest of
;; the in-buffer settings arrive as plain metadata. But `org-meta-line' is also
;; every #+begin_src, #+end_src, #+RESULTS:, #+name: and #+caption: in the file,
;; so tinting that face would paint half of a source-heavy note purple. The two
;; groups have to be told apart by keyword, not by face.
;;
;; Rather than keep a hand-written list of the settings half, take org's own:
;; `org-options-keywords' is precisely the set of keywords that configure a
;; document, and it is what org uses for `pcomplete' on `#+'. Deriving from it
;; means a keyword added by a future org version is picked up for free, and
;; there is no second list here to drift out of sync. Only SUBTITLE: is added
;; by hand -- org handles it in the special-case branch above, so it never
;; needed to be in the completion list. (`org-options-keywords' is a defconst in
;; org.el, which is loaded well before this point via org-roam.)
(defconst os-org-document-keyword-regexp
  (concat "^[ \t]*\\(#\\+"
          (regexp-opt (cons "SUBTITLE:" org-options-keywords))
          "\\)")
  "Match a document-configuring `#+keyword:' and nothing else.
Group 1 is the keyword together with its `#+' and its colon; the value
after it is deliberately outside the group.  Built from
`org-options-keywords', so it covers the in-buffer settings but not
`#+begin_src', `#+results:' or the other content-level meta lines.")

;; A matcher function rather than the regexp itself, purely to get
;; case-insensitivity: org sets the CASE-FOLD slot of `font-lock-defaults' to
;; nil, so a font-lock regexp is matched case-sensitively, and
;; `org-options-keywords' is upper case while nobody writes `#+STARTUP:' that
;; way. Binding `case-fold-search' around the search is the only place that can
;; be fixed without either shouting in every org file or spelling out
;; `[sS][tT][aA]...' by hand.
(defun os-org-match-document-keyword (limit)
  "Search for the next document keyword before LIMIT, ignoring case.
A font-lock MATCHER for `os-org-document-keyword-regexp'."
  (let ((case-fold-search t))
    (re-search-forward os-org-document-keyword-regexp limit t)))

;; `font-lock-add-keywords' appends after org's own keywords and the OVERRIDE
;; flag is t, so this wins the keyword. Subexpression 1, not 0, keeps the tint
;; off the value -- the same split org itself makes on `#+title:'.
(font-lock-add-keywords
 'org-mode
 '((os-org-match-document-keyword 1 'org-document-info-keyword t))
 'append)

;; The active theme. This is the only place it is set: the Custom block at the
;; end of this file must not carry `custom-enabled-themes' -- it runs later, and
;; its setter disables every other theme, so a value there silently overrides
;; whatever is loaded here. M-x customize-themes followed by a save writes it
;; back; delete it again and change this line instead.
;; Local Julia variants reuse Leuven's package coverage and font-family
;; variations, with Julia green/red/blue/purple roles (blue/red, then
;; red/green swapped by preference from Leuven), and tinted Org bands.  Resolve beside the real init file because user-emacs-directory is
;; a symlinked deployment location, while these themes belong to the repo.
;; Keep the active choice here, alongside the other theme configuration.
(add-to-list 'custom-theme-load-path
             (expand-file-name "themes" (file-name-directory
                                        (file-truename
                                         (or load-file-name user-init-file)))))
;; Three independently selectable themes: white paper, pale green paper, and
;; charcoal.  Keep green paper as the startup choice; cycling or selecting a
;; variant disables the current theme first so faces never accumulate.
(defun os-julia-theme-select (theme)
  "Select one of the three Julia Leuven themes interactively."
  (interactive
   (list (intern (completing-read
                  "Julia theme: "
                  '("julia-leuven-light" "julia-leuven-light-green"
                    "julia-leuven-dark") nil t))))
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme theme t))
(defun os-julia-theme-toggle ()
  "Cycle Julia Leuven themes: white, pale green, dark."
  (interactive)
  (let* ((themes '(julia-leuven-light julia-leuven-light-green julia-leuven-dark))
         (current (seq-find (lambda (theme) (memq theme custom-enabled-themes))
                            themes))
         (next (or (cadr (memq current themes)) (car themes))))
    (os-julia-theme-select next)))
(mapc #'disable-theme custom-enabled-themes)
(load-theme 'julia-leuven-light-green :no-confirm)

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

;; --- Automatic delimiter pairing (built-in) ---------------------------------
;; Insert the matching closing delimiter as an opening parenthesis, bracket,
;; brace or quote is typed, leaving point between the pair.  electric-pair
;; follows each buffer's syntax table and skips an existing closing delimiter
;; when it is typed, so ordinary typing does not duplicate it.  Enable it
;; globally for existing and future buffers instead of only in TeX buffers.
(electric-pair-mode 1)

;; --- Session persistence (built-ins) -----------------------------------------
;; savehist-mode   -- persist minibuffer histories (M-x, file prompts, org-roam
;;                    searches) across sessions.
;; recentf-mode    -- track recently visited files; `recentf-open' completes
;;                    over them. C-x C-r shadows `find-file-read-only', which
;;                    reads better as a recent-files key than as its default.
;; save-place-mode -- reopen every file at the position point last had in it.
(savehist-mode 1)
(recentf-mode 1)
(setq recentf-max-saved-items 200)
(global-set-key (kbd "C-x C-r") #'recentf-open)
(save-place-mode 1)

;; Keep backup files (`foo~') and auto-save files (`#foo#') out of working
;; directories, where they litter dired listings, grep results and git status.
;; Both go under ~/.emacs.d with the rest of the generated state. Emacs creates
;; the backup directory itself, but the auto-save one must already exist.
(setq backup-directory-alist
      `(("." . ,(expand-file-name "backups" user-emacs-directory))))
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-saves/" user-emacs-directory) t)))
(make-directory (expand-file-name "auto-saves" user-emacs-directory) t)

;; --- Default font -----------------------------------------------------------
;; JuliaMono Nerd Font Mono (includes Nerd Font glyphs/icons). Applies to the
;; current and all future frames.
(set-face-attribute 'default nil :family "JuliaMono Nerd Font Mono" :height 130)
(add-to-list 'default-frame-alist '(font . "JuliaMono Nerd Font Mono-13"))
;; `fixed-pitch' ships as family "Monospace", which fontconfig resolves to a
;; different mono font (DejaVu/Noto).  The Julia Leuven themes make org tables,
;; blocks, code and verbatim inherit `fixed-pitch' and leave its family to the
;; user, so without this those spans render in another font than the text
;; around them.  No :height -- it stays relative to `default'.
(set-face-attribute 'fixed-pitch nil :family "JuliaMono Nerd Font Mono")

;; --- Git (magit + diff-hl) --------------------------------------------------
;; magit: the Git porcelain. Autoloaded, so just bind the usual entry point
;; rather than `require'-ing the whole thing at startup.
(global-set-key (kbd "C-x g") #'magit-status)
;; diff-hl: show added/changed/removed lines in the fringe, live, in every
;; file-visiting buffer. Keep its indicators in sync with magit commits/stages.
;; Only the post-refresh hook is needed: diff-hl 1.11 folded the old
;; pre-refresh step into it (`diff-hl-magit-pre-refresh' is now an obsolete
;; alias for `ignore').
(require 'diff-hl)
(global-diff-hl-mode 1)
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

;; cape: extra `completion-at-point' sources layered *behind* whatever the
;; mode or language server already provides -- file paths anywhere, and
;; dabbrev (words already present in open buffers) as a last resort. Both are
;; appended (the trailing t) so a live LSP server's candidates always win;
;; cape only speaks up where the server has nothing to say.
(require 'cape)
(add-to-list 'completion-at-point-functions #'cape-file t)
(add-to-list 'completion-at-point-functions #'cape-dabbrev t)

;; --- Minibuffer completion (vertico + orderless + marginalia + consult + embark)
;; corfu above is completion *in the buffer*; this stack is the same idea for
;; the minibuffer. Five small packages that all ride the standard
;; `completing-read' machinery rather than replacing it (no helm/ivy
;; framework), so every prompt -- M-x, find-file, org-roam-node-find, lsp's
;; own pickers -- benefits without per-command integration:
;;   vertico    -- vertical, live-filtered candidate list.
;;   orderless  -- match space-separated terms in any order ("roam find"
;;                 matches org-roam-node-find). Plugged in via
;;                 `completion-styles', which corfu consults too, so in-buffer
;;                 LSP completion gets the same flexible matching for free.
;;   marginalia -- annotations beside candidates (command docstrings and
;;                 keybindings, file sizes/dates, buffer modes).
;;   consult    -- enhanced versions of stock commands over that machinery;
;;                 bound below where they beat the built-in outright.
;;   embark     -- context actions on the candidate/thing at point; C-. is
;;                 "right-click as a keystroke" (kill the buffer under the
;;                 cursor in consult-buffer, insert the candidate, ...).
;; savehist-mode (above) already persists the histories vertico sorts by.
(vertico-mode 1)
(marginalia-mode 1)
(setq completion-styles '(orderless basic))
(setq completion-category-defaults nil)
;; Keep `basic' first for files so TRAMP method/host completion still works,
;; and partial-completion so /u/sh/e still expands to /usr/share/emacs.
(setq completion-category-overrides
      '((file (styles basic partial-completion))))

;; consult bindings. Deliberately conservative: C-s stays isearch (muscle
;; memory; consult-line lives on the standard M-s search prefix instead), and
;; C-x C-r stays recentf-open (consult-buffer lists recent files anyway).
(global-set-key (kbd "C-x b")   #'consult-buffer)     ; buffers + recent + bookmarks
(global-set-key (kbd "M-g g")   #'consult-goto-line)  ; goto-line with live preview
(global-set-key (kbd "M-g M-g") #'consult-goto-line)
(global-set-key (kbd "M-g i")   #'consult-imenu)      ; sections/defuns in buffer
(global-set-key (kbd "M-s l")   #'consult-line)       ; search lines, pick from list
(global-set-key (kbd "M-s r")   #'consult-ripgrep)    ; rg across the project
;; Route xref result lists (eglot/lsp find-references, multi-hit
;; find-definition) through consult's selectable list instead of a *xref*
;; window.
(setq xref-show-xrefs-function #'consult-xref)
(setq xref-show-definitions-function #'consult-xref)

(global-set-key (kbd "C-.")   #'embark-act)
(global-set-key (kbd "C-;")   #'embark-dwim)
(global-set-key (kbd "C-h B") #'embark-bindings)
;; Glue package: embark actions/exports on consult candidate lists (e.g.
;; export a consult-ripgrep search to a grep buffer with E).
(with-eval-after-load 'consult (require 'embark-consult))

;; which-key ships with Emacs 30: when a prefix key pauses, pop up the table
;; of its completions. This is the discovery aid for the C-c C-* space that
;; ESS, org-roam and the LSP clients all populate.
(require 'which-key)
(which-key-mode 1)

;; --- Documentation display (eldoc) ----------------------------------------------------
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
;;
;; The graphics check has to run per-buffer, not at init: under `emacs
;; --daemon' no frame exists while init runs, so a top-level
;; `display-graphic-p' is nil and GUI frames created later would silently
;; never get the popup. Deciding inside the hook tests the frame the buffer
;; actually appears on. And since lsp-mode publishes its hover docs through
;; eldoc exactly as eglot does, hook both clients.  Python/R keep the popup;
;; Julia updates the documentation buffer quietly; C-h . requests the current
;; docstring in a scrollable right side window.  Automatic updates never open
;; or reopen that window, so closing it keeps the editing area clear.
;; Dispatch when the client attaches as well as when Julia mode starts, since
;; LSP may initialise asynchronously after the major-mode hook has finished.
(defun my-julia-eldoc-display-in-buffer (docs interactive)
  "Update Julia DOCS; open the right side window only when INTERACTIVE."
  (when docs
    (let ((display-buffer-alist
           (cons '("\\` ?\\*eldoc\\*\\'"
                   (display-buffer-reuse-window display-buffer-in-side-window)
                   (side . right) (slot . 0) (window-width . 0.35))
                 display-buffer-alist)))
      (eldoc-display-in-buffer docs interactive)))
  t)

(defun my-julia-show-documentation ()
  "Request Julia hover docs directly, or use the REPL when LSP is absent.
JETLS documentation is rendered in the right-hand ElDoc window.  Without
an attached hover-capable server, use `julia-repl-doc' and *julia-doc*."
  (interactive)
  (if (and (bound-and-true-p lsp-mode)
           (lsp-workspaces) (lsp-feature? "textDocument/hover"))
      (let ((source (current-buffer)))
        (lsp-request-async
         "textDocument/hover" (lsp--text-document-position-params)
         (lambda (hover)
           (when (buffer-live-p source)
             (with-current-buffer source
               (let* ((contents (and hover (lsp:hover-contents hover)))
                      (text (and contents
                                 (lsp--render-on-hover-content contents t))))
                 (if (and (stringp text)
                          (not (string-empty-p (string-trim text))))
                     (my-julia-eldoc-display-in-buffer (list (list text)) t)
                   (message "JETLS returned no documentation here; use C-c C-d to query the running REPL."))))))
         :mode 'detached
         :error-handler
         (lambda (error)
           (message "Julia documentation request failed: %s; use C-c C-d for REPL docs."
                    error))))
    (require 'julia-repl)
    (julia-repl-doc)))

(defun my-julia-eldoc-use-buffer ()
  "Route Julia documentation to a scrollable buffer instead of eldoc-box."
  (when (derived-mode-p 'julia-mode 'julia-ts-mode)
    (when (bound-and-true-p eldoc-box-hover-at-point-mode)
      (eldoc-box-hover-at-point-mode -1))
    (when (bound-and-true-p eldoc-box-hover-mode)
      (eldoc-box-hover-mode -1))
    ;; Show available providers eagerly: a pending signature provider should
    ;; not hold back hover documentation from updating the documentation buffer.
    (setq-local eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)
    (setq-local eldoc-display-functions '(my-julia-eldoc-display-in-buffer))
    (local-set-key (kbd "C-h .") #'my-julia-show-documentation)))

(defun my-eldoc-box-enable-if-graphic ()
  "Use a documentation buffer for Julia, graphical eldoc-box otherwise."
  (if (derived-mode-p 'julia-mode 'julia-ts-mode)
      (my-julia-eldoc-use-buffer)
    (when (display-graphic-p)
      (eldoc-box-hover-at-point-mode 1))))
(add-hook 'julia-mode-hook #'my-julia-eldoc-use-buffer)
(add-hook 'julia-ts-mode-hook #'my-julia-eldoc-use-buffer)
;; Also update existing Julia buffers when init.el is reloaded.
(dolist (buffer (buffer-list))
  (with-current-buffer buffer
    (my-julia-eldoc-use-buffer)))
(add-hook 'eglot-managed-mode-hook #'my-eldoc-box-enable-if-graphic)
(add-hook 'lsp-managed-mode-hook #'my-eldoc-box-enable-if-graphic)
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
;; lsp-mode still drives Python (basedpyright), Julia (JETLS) and R
;; (languageserver).
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

;; Snippet-style completions (function signatures that expand with tab-stops):
;; yasnippet is installed (see the Python IDE section), so let lsp-mode hand
;; templates to it. This used to be nil, when yasnippet wasn't here.
(setq lsp-enable-snippet t)

;; Diagnostics land in flymake (no flycheck installed; lsp-mode's :auto
;; provider falls back to it). Its jump commands ship unbound, so give them
;; the conventional M-n/M-p inside flymake buffers.
(with-eval-after-load 'flymake
  (keymap-set flymake-mode-map "M-n" #'flymake-goto-next-error)
  (keymap-set flymake-mode-map "M-p" #'flymake-goto-prev-error))

;; Python: basedpyright via the lsp-pyright package (which speaks for both
;; pyright flavours -- `lsp-pyright-langserver-command' picks). This replaced
;; (2026-08) pylsp from a dedicated conda env after conda disappeared from the
;; machine: basedpyright is the community pyright fork that ships on PyPI with
;; a bundled Node.js, so `uv tool install basedpyright' is the whole install
;; (lands in ~/.local/bin, which exec-path-from-shell puts on Emacs' PATH).
(setq lsp-pyright-langserver-command "basedpyright")
;; One server per project, each seeing only its own virtualenv. Multi-root is
;; lsp-pyright's default, but a shared server applies whichever venv it found
;; first to every workspace folder -- wrong diagnostics everywhere else. Must
;; be set before lsp-pyright loads; when flipping it on an existing install,
;; delete ~/.emacs.d/.lsp-session-v1 or the recorded multi-root session wins.
(setq lsp-pyright-multi-root nil)
(require 'lsp-pyright)

;; consult-lsp: lsp-mode's diagnostics/workspace-symbol pickers in the consult
;; UI the rest of the minibuffer stack uses. Remaps (C-c l g e / C-c l g a
;; reach them) rather than new bindings; the commands are autoloaded, so no
;; require -- consult and consult-lsp load on first use.
(define-key lsp-mode-map [remap lsp-treemacs-errors-list] #'consult-lsp-diagnostics)
(define-key lsp-mode-map [remap xref-find-apropos] #'consult-lsp-symbols)

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

;; julia-repl: interactive REPL for Julia, the counterpart of what ESS provides
;; for R. JETLS covers the static side (diagnostics, completion, docs) but has
;; no way to *run* code; julia-repl adds send-to-REPL (C-c C-c and friends) on
;; top of a live `julia' session. Chosen over julia-snail deliberately: snail
;; ships its own completion/xref backends fed by the running session, which
;; would compete with lsp-mode's -- the single-completion-source rule that
;; `lsp-completion-provider :none' enforces elsewhere. julia-repl just pastes
;; into a terminal, so it cannot conflict with the LSP stack. The minor mode is
;; autoloaded, so no require here; the backend is set once julia-repl actually
;; loads (first Julia buffer). vterm as the terminal backend matches the vterm
;; already installed for general use. Note `julia-repl-set-terminal-backend'
;; itself does (require 'vterm), so opening the first Julia buffer loads vterm
;; -- still off the startup path, which is all the vterm rule above demands.
;;
;; `--project=@.' makes the REPL use the same environment JETLS analyses: Julia
;; walks up from the working directory (the source buffer's, since the vterm
;; starts there) to the nearest Project.toml, which is JETLS's own rule, and
;; falls back to the default environment when there is none. Without it the REPL
;; opens in ~/.julia/environments/vX.Y until C-c C-a is pressed. The *version*
;; is not set here: bare `julia' follows juliaup's default, and no project has a
;; directory override. There is one REPL per buffer-name suffix, not per project,
;; so the project is fixed when it starts.
(add-hook 'julia-mode-hook #'julia-repl-mode)
;; C-c C-d sends @doc to the running REPL.  EmacsVterm.jl (loaded by the
;; companion Julia startup file) returns rendered HTML through vterm's
;; explicitly allowed julia-repl--show command.  Reuse a persistent right
;; side window for the clean documentation buffer; ElDoc remains on C-h .
(add-to-list 'display-buffer-alist
             '("\\`\\*julia-doc\\*\\'"
               (display-buffer-reuse-window display-buffer-in-side-window)
               (side . right) (slot . 0) (window-width . 80)))

;; Native Julia 1.13 highlighting defaults leave functions/types/numbers plain.
;; Load the companion face mapping at REPL startup; ANSI slots are supplied by
;; the Julia Leuven themes, so all four logo colours follow the editor palette.
;; --color=yes ensures the terminal backend receives colour escapes explicitly.
(defvar my-julia-repl-colors-file
  (expand-file-name "julia-repl-colors.jl"
                    (file-name-directory (file-truename
                                          (or load-file-name user-init-file)))))
(with-eval-after-load 'julia-repl
  (setq julia-repl-switches
        (concat "--project=@. --color=yes --load="
                (shell-quote-argument my-julia-repl-colors-file)))
  (julia-repl-set-terminal-backend 'vterm))

;; Format-on-save with Runic, routed through JETLS rather than run directly.
;; JETLS already defaults to Runic (`formatter = "Runic"' in its DEFAULT_CONFIG)
;; and serves textDocument/formatting by shelling out to a `runic' executable --
;; installed with `julia -e "using Pkg; Pkg.Apps.add(\"Runic\")"', which lands it
;; in ~/.julia/bin next to jetls and so on the same juliaup-provided PATH. The
;; LSP client is therefore already a Runic client, and all that is missing here
;; is the save hook.
;;
;; Deliberately NOT a second `reformatter-define' like Air below: R's
;; languageserver knows nothing about Air, so there is no LSP path to route
;; through and reformatter is the only option there. Here there is one, and
;; adding a direct `runic' route beside it would put two formatters over the same
;; buffer -- the same single-source rule that keeps completion on one backend.
;;
;; Guarded twice over, so nothing here can block a save: `lsp-feature?' (an alias
;; for `lsp--find-workspaces-for') returns nil in any buffer with no server
;; attached, which covers scratch .jl files outside a project, and
;; `executable-find' covers machines where Runic was never installed -- both
;; degrade to no formatting rather than an error, matching the Air guard below.
;; Note this shares the JETLS process with analysis, so a save landing inside a
;; full-analysis window waits for that to finish.
(defun my-julia-runic-format ()
  "Format the current Julia buffer with Runic, via JETLS.
No-op unless a server offering formatting is attached and `runic'
is installed, so a save never fails on a missing piece."
  (when (and (lsp-feature? "textDocument/formatting")
             (executable-find "runic"))
    (lsp-format-buffer)))

(defun my-julia-enable-runic ()
  "Format Julia buffers with Runic on save."
  (add-hook 'before-save-hook #'my-julia-runic-format nil t))

(add-hook 'julia-mode-hook #'my-julia-enable-runic)

;; JETLS analyses a file only when it is opened and on didSave -- never on
;; didChange -- and it is that analysis which actually loads packages. So a
;; freshly typed `using Pluto' gives no `Pluto.' completion or hover until the
;; next save: to the server, `Pluto' does not exist yet. Rather than saving for
;; real (which would run Runic mid-edit), re-send didSave from lsp-mode's idle
;; hook whenever the using/import lines change. JETLS analyses the text carried
;; by the notification, not the file, so nothing touches the disk.
;;
;; `lsp--text-document-did-save' is what `after-save-hook' calls; it writes
;; nothing itself. The `buffer-modified-p' check skips the case a real save has
;; just covered. Limit: JETLS skips analysis of text that does not parse, so a
;; `using' pasted together with an unfinished line stays unloaded until a save
;; once the code parses again.
(defvar-local my-julia-known-imports nil
  "This buffer's using/import lines as of the last JETLS analysis.")

(defun my-julia-import-lines ()
  "Return the using/import lines of the current buffer."
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (let (lines)
        (while (re-search-forward "^[ \t]*\\(?:using\\|import\\)\\_>.*$" nil t)
          (push (match-string-no-properties 0) lines))
        lines))))

(defun my-julia-analyse-new-imports ()
  "Have JETLS analyse the buffer if its using/import lines changed."
  (let ((imports (my-julia-import-lines)))
    (unless (equal imports my-julia-known-imports)
      (setq my-julia-known-imports imports)
      (when (buffer-modified-p)
        (lsp--text-document-did-save)))))

(defun my-julia-enable-import-analysis ()
  "Analyse new using/import lines in this buffer without saving it."
  (setq my-julia-known-imports (my-julia-import-lines))
  (add-hook 'lsp-on-idle-hook #'my-julia-analyse-new-imports nil t))

(add-hook 'julia-mode-hook #'my-julia-enable-import-analysis)

;; The ChkTeX settings that used to live here were texlab-specific (it is texlab
;; that shells out to ChkTeX; digestif does not), so they went with it. digestif
;; is quiet by comparison -- it reports unknown commands and bad references, and
;; does not lint half-typed macros -- so there is no equivalent noise to tame.

;; Global electric-pair-mode above also closes TeX braces, keeping partial
;; commands balanced while digestif checks the buffer.

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

;; --- LSP inside Org src-block edit buffers ------------------------------------
;; C-c ' (org-edit-special) edits a block in an *Org Src* buffer that visits no
;; file. The mode hooks above do run there, but lsp-mode refuses fileless
;; buffers -- a server needs a file URI and a project root -- so LSP never
;; attaches in those buffers. Org's escape hatch is `org-babel-edit-prep:LANG',
;; called with the block's babel info once the edit buffer is fully set up:
;; give the buffer a file name there, then start lsp. The name is the block's
;; :tangle target when it names a file; otherwise a phantom "<file>.org.<ext>"
;; beside the org file, which roots the server in the org file's directory.
;; Nothing ever writes to that path: C-c ' and C-x C-s in a src buffer go
;; through org-src's `write-contents-functions' (which writes back to the org
;; buffer and returns non-nil, short-circuiting a real save), and
;; `org-edit-src-exit' clears the modified flag before killing the buffer, so
;; the phantom name never triggers save/kill prompts.
(defun my-org-src-lsp (info ext)
  "Give the current org-src edit buffer a file name and start lsp.
INFO is the babel info passed to `org-babel-edit-prep:LANG'; EXT is
the file extension for the block's language."
  (let* ((tangle (cdr (assq :tangle (nth 2 info))))
         (org-file (buffer-file-name (org-src-source-buffer))))
    (setq-local buffer-file-name
                (cond ((and tangle (not (member tangle '("no" "yes"))))
                       (expand-file-name
                        tangle (and org-file (file-name-directory org-file))))
                      (org-file (concat org-file "." ext))
                      (t (expand-file-name (concat "org-src-scratch." ext)
                                           temporary-file-directory))))
    (lsp-deferred)))

(defun org-babel-edit-prep:python (info) (my-org-src-lsp info "py"))
(defun org-babel-edit-prep:julia  (info) (my-org-src-lsp info "jl"))
(defun org-babel-edit-prep:R      (info) (my-org-src-lsp info "R"))

;; --- Python IDE (snippets + debugging + environments) ------------------------
;; The rest of the Python stack, after the LSP half above. Modelled on
;; https://blog.serghei.pl/posts/emacs-python-ide/ but adapted to this
;; config's choices: corfu instead of the post's company (snippets join
;; completion through a capf, not a company backend), and uv instead of its
;; pyenv -- projects are created/synced with `uv init' / `uv sync', which puts
;; the virtualenv in .venv/ where lsp-pyright finds it unaided. direnv+envrc
;; (end of file) layer per-project env vars on top when an .envrc exists.
;;
;; yasnippet: the template engine. Loaded eagerly because `lsp-enable-snippet'
;; above needs it in any LSP buffer (it expands completion templates for
;; Julia/R too, not just Python). yasnippet-snippets is the community snippet
;; library; `yas-reload-all' builds the tables once, and yas-minor-mode is
;; then enabled per prog-mode buffer rather than globally, which keeps TAB in
;; org/text buffers untouched.
(require 'yasnippet)
(require 'yasnippet-snippets)
(yas-reload-all)
(add-hook 'prog-mode-hook #'yas-minor-mode)

;; Per-buffer Python setup. dap-mode is required here, not at startup: it
;; drags in treemacs and friends, which sessions that never open Python
;; shouldn't pay for. debugpy is the debug server and must be importable by
;; the interpreter that runs the code -- `uv add --dev debugpy' per project.
;; Templates offered by `dap-debug' include "Python :: Run file (buffer)" and
;; pytest variants; breakpoints via `dap-breakpoint-toggle'.
(defun my-python-ide-setup ()
  "Snippet completion and DAP debugging for Python buffers."
  ;; Offer snippets as completion candidates next to the LSP's: corfu reads
  ;; capfs, so yasnippet needs a capf shim (the post's company-yasnippet
  ;; backend translated to this stack).
  (add-hook 'completion-at-point-functions #'yasnippet-capf nil t)
  (require 'dap-python)
  (setq dap-python-debugger 'debugpy)
  (dap-auto-configure-mode 1))

(add-hook 'python-mode-hook #'my-python-ide-setup)
(add-hook 'python-ts-mode-hook #'my-python-ide-setup)

;; --- R (ESS + Air + Quarto) --------------------------------------------------
;; ESS is the R IDE core: `ess-r-mode' for source files, an inferior R
;; process (M-x R) beside them, and the C-c C-* keys to move code across --
;; C-c C-c sends the region/function/paragraph and steps, C-c C-z hops to the
;; console. (That C-c C-c behaviour is ESS's own default binding; no need to
;; rebind it.) The lsp-deferred hook above layers languageserver on top for
;; diagnostics/rename/references. ESS is autoload-driven, so only settings
;; live here; nothing to require at startup.
;;
;; R here is Fedora's rpm (4.6.x); `languageserver' is installed in the user
;; library (~/R/...). Its `fs' dependency compiles against libuv, so a fresh
;; machine needs `dnf install libuv-devel' before
;; `install.packages("languageserver")' -- without it, fs/pkgload/roxygen2/
;; languageserver all fail in a cascade.
(setq ess-style 'RStudio)            ; plain indentation, no aggressive
                                     ; argument alignment -- matches Air's output
(setq ess-ask-for-ess-directory nil) ; don't prompt for a directory on M-x R
(setq ess-eval-visibly 'nowait)      ; echo sent code without blocking Emacs
;; ESS's own flymake backend (lintr) would double-report next to the lintr
;; diagnostics languageserver already publishes through lsp-mode.
(setq ess-use-flymake nil)

(defun my-ess-r-mode-setup ()
  "Buffer-local niceties for R source buffers."
  ;; 80 columns is Air's default line width; draw the guide at the same place
  ;; the formatter wraps.
  (setq-local fill-column 80)
  (display-fill-column-indicator-mode 1)
  ;; Nested calls are R's bread and butter; tint the parens by depth.
  (rainbow-delimiters-mode 1))
(add-hook 'ess-r-mode-hook #'my-ess-r-mode-setup)

;; Air (Posit's R formatter, installed to ~/.local/bin -- reachable in GUI
;; sessions via exec-path-from-shell above): format R buffers on save, wired
;; up with reformatter. `air format --stdin-file-path FILE' reads the buffer
;; from stdin and writes the result to stdout; the path is used only to
;; locate an air.toml and apply that project's settings/exclusions -- the
;; file itself is never read. reformatter evaluates :args in the buffer being
;; formatted, so `buffer-file-name' is the right file each time (with a
;; fallback for never-saved buffers, where Air just uses its defaults).
(require 'reformatter)
(reformatter-define air-format
  :program "air"
  :args (list "format" "--stdin-file-path"
              (or buffer-file-name
                  (expand-file-name "stdin.R" default-directory)))
  :lighter " Air")
(defun my-ess-r-enable-air ()
  "Turn on format-on-save via Air when the executable is available.
Guarded so a machine without Air degrades to no formatting instead
of erroring on every save."
  (when (executable-find "air")
    (air-format-on-save-mode 1)))
(add-hook 'ess-r-mode-hook #'my-ess-r-enable-air)

;; Quarto (.qmd): quarto-mode's autoloads already map .qmd files to
;; `poly-quarto-mode', where polymode carves the buffer into markdown prose
;; and R chunks -- each chunk served by ess-r-mode, and so by lsp/corfu/Air
;; exactly as a plain .R buffer would be. Rendering and preview additionally
;; need the `quarto' CLI, which is not installed yet; editing works without
;; it. Nothing to require at startup.

;; --- Email (mu4e) -----------------------------------------------------------
;; mu4e and its `mu' indexer ship together in Fedora's `maildir-utils' package.
;; Fedora installs the Lisp files in /usr/share/emacs/site-lisp/mu4e, while
;; Debian uses a versioned /usr/share/emacs/site-lisp/elpa/mu4e-<version>
;; directory. Add whichever layout exists so this config remains portable.
;; mu4e is the front end only -- mail is fetched by OfflineIMAP into ~/.maildir
;; and indexed by `mu', and sent via msmtp.
(let ((mu4e-dir
       (seq-find
        #'file-directory-p
        (append '("/usr/share/emacs/site-lisp/mu4e")
                (reverse
                 (file-expand-wildcards
                  "/usr/share/emacs/site-lisp/elpa/mu4e-*"))))))
  (when mu4e-dir
    (add-to-list 'load-path mu4e-dir)))
;; Mail is an optional system-level component. Do not make a missing system
;; package fatal to all of Emacs; the settings below remain ready for whenever
;; mu4e is installed.
(require 'mu4e nil :noerror)

;; How mu4e refreshes mail. `-o' runs a one-shot sync (no held connection).
;; No `-q': OfflineIMAP refuses to quick-sync an account that sets maxage
;; (ours does, offlineimaprc) and just prints "ignoring -q" per folder, so the
;; flag bought nothing but a warning -- every sync is a full scan of each
;; folder's 30-day window regardless. The maildir root (~/.maildir) is
;; deliberately NOT set here: since mu 1.3.8 the mu server owns that path,
;; recorded once by `mu init --maildir=~/.maildir', and the old `mu4e-maildir'
;; variable is obsolete -- mu4e ignores it in favour of the server's answer.
(setq mu4e-get-mail-command "offlineimap -o")
;; 10 minutes, not 5: Gmail rate-limits accounts that issue too many IMAP
;; commands (observed 2026-07-28 as a flat ~10 s delay on every command after
;; login, which made each sync take 10+ minutes and overlap the next timer
;; firing -- keeping the account permanently throttled). Each one-shot
;; offlineimap run walks all ~25 folders, so the polling interval is the
;; multiplier on total command volume; don't lower it back below this.
(setq mu4e-update-interval 600)
;; OfflineIMAP (like mbsync) rewrites message filenames on sync, so mu4e must
;; rename rather than assume stable names -- required or moves/flags desync.
(setq mu4e-change-filenames-when-moving t)
(setq mu4e-attachment-dir "~/Downloads")

;; Headers view: add a dedicated attachment column. The stock Flgs column
;; already encodes attachments (the `a' among its letters, from the `attach'
;; flag mu sets on messages with real attachments), but a lone paperclip
;; glyph is scannable where a letter buried in `Rap' is not.
;; `mu4e-header-info-custom' is mu4e's extension point for computed columns:
;; the :function receives the message plist at render time. nerd-icons is
;; already loaded at startup as a doom-modeline dependency, and its glyphs
;; are single-width in JuliaMono Nerd Font Mono -- an emoji paperclip would
;; be double-width and break column alignment. Guarded like everything
;; mu4e-related: a missing mu4e must not break startup (`add-to-list' on an
;; undefined variable would, unlike the plain setqs above).
(when (featurep 'mu4e)
  (add-to-list 'mu4e-header-info-custom
               '(:attach
                 :name "Attach" :shortname "A"
                 :help "Message has attachments"
                 :function (lambda (msg)
                             (if (memq 'attach (mu4e-message-field msg :flags))
                                 (nerd-icons-faicon "nf-fa-paperclip")
                               " "))))
  ;; The default field list with :attach slotted in after the flags, and
  ;; :from-or-to in place of :from. In Sent/Drafts every message is from
  ;; oneself, so a From column is a wall of one's own name; :from-or-to shows
  ;; the To: address instead whenever From: matches `mu4e-personal-address-p'
  ;; -- i.e. one of the addresses recorded in the mu store by
  ;; `mu init --my-address=...' (check with `mu info store'); mu4e-vars.el
  ;; states plainly that the check is the store's list, not `user-mail-address',
  ;; so adding an alias means re-running `mu init'/`mu index', not a setq here.
  ;; Those rows get the "To " prefix from `mu4e-headers-from-or-to-prefix',
  ;; which costs 3 columns, hence 25 rather than the stock 22.
  (setq mu4e-headers-fields
        '((:human-date . 12)
          (:flags . 6)
          (:attach . 2)
          (:mailing-list . 10)
          (:from-or-to . 25)
          (:subject))))

;; Calendar invites -> org agenda. gnus-icalendar (built-in; it is what
;; already renders the Accept/Tentative/Decline buttons on text/calendar
;; messages in the mu4e view) ships an org exporter: `gnus-icalendar-org-setup'
;; adds an "Export to Org" button to every invite and registers the capture
;; template it uses (key "#" -- keep custom templates off that key). Exported
;; events become entries with org timestamps under the "Invitations" headline
;; of the file below. The file lives under the org repo's agenda/ tree, so
;; org-config.el's `organization-org-files' pulls it into `org-agenda-files'.
;; RSVP-ing from mu4e also updates the exported entry's state. org is already
;; loaded at startup (org-roam above), so the require is cheap here.
(when (featurep 'mu4e)
  ;; mu4e's adapter for gnus-icalendar: advises the reply machinery so the
  ;; Accept/Tentative/Decline buttons send through mu4e (msmtp) instead of
  ;; gnus' own sending stack. mu4e-icalendar.el's commentary documents this
  ;; require + gnus-icalendar-setup as the supported installation.
  (require 'mu4e-icalendar)
  (gnus-icalendar-setup)
  (require 'gnus-icalendar)
  ;; The org-buttons row probes whether the event is already in the org files
  ;; (`gnus-icalendar-find-org-event-file'), which touches org-agenda
  ;; internals. org itself is loaded at startup (org-roam) but org-agenda is
  ;; not -- and without it the probe dies with (void-variable
  ;; org-agenda-archives-mode) mid-render: the Accept/Decline buttons appear,
  ;; the Export-to-Org row silently doesn't.
  (require 'org-agenda)
  (setq gnus-icalendar-org-capture-file
        "~/slimer/agenda/invites.org")
  (setq gnus-icalendar-org-capture-headline '("Invitations"))
  (gnus-icalendar-org-setup)
  ;; Duplicate-protection depends on the capture file being findable: the
  ;; export button looks the event's UID up in `org-agenda-files' and only
  ;; offers "Update Org Entry" when found. The org repo's org-config.el sets
  ;; org-agenda-files (loaded at startup by the Calendar section above when
  ;; the repo exists), but on a machine without the repo the variable would
  ;; be empty, every press would append a fresh duplicate, and the button
  ;; would never change label. Registering the capture file here keeps
  ;; lookups working regardless; when org-config.el loads it rebuilds the
  ;; list wholesale and picks this file up again via its agenda/ scan.
  (add-to-list 'org-agenda-files gnus-icalendar-org-capture-file)
  ;; The capture template is :immediate-finish -- a successful export shows
  ;; nothing at all, which reads as a dead button. Say what happened.
  (advice-add 'gnus-icalendar-sync-event-to-org :after
              (lambda (&rest _)
                (message "Invite exported to %s"
                         gnus-icalendar-org-capture-file))))

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

;; Jump-to-folder shortcuts (the `j' command in the headers/main view).
;; Keep the main view focused on these four frequently used folders.
(setq mu4e-maildir-shortcuts
      '((:maildir "/gmail/INBOX"             :key ?i)
        (:maildir "/gmail/[Gmail].Sent Mail" :key ?s)
        (:maildir "/gmail/[Gmail].Drafts"    :key ?d)
        (:maildir "/gmail/@citystgeorges"    :key ?c)))

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

;; Inline images. Zulip messages arrive as rendered HTML and zulip-ui hands
;; them to shr, which fetches every <img> itself via `url-queue-retrieve'.
;; Out of the box every image stays a gray placeholder box, for two stacked
;; upstream bugs:
;;
;; 1. Image URLs in message HTML are relative ("/user_uploads/...").
;;    `zulip--insert-content' tries to hand shr a base URL by let-binding
;;    `shr-base', but `shr-insert-document' rebinds `shr-base' to nil on
;;    entry, so the binding is discarded (it also holds the wrong type --
;;    `url-generic-parse-url' output where shr expects `shr-parse-base'
;;    output). The relative URL reaches `url-retrieve' inside url-queue's
;;    `ignore-errors', which chokes silently; the job just rots in the queue.
;;    The way that works (eww does this) is wrapping the DOM in a synthetic
;;    (base ((href . url)) ...) node, which shr's own `shr-tag-base' picks up
;;    inside that rebinding -- so override `zulip--insert-content' with a copy
;;    that does exactly that. Drop the override when upstream fixes it.
;;
;; 2. With URLs absolutized, the fetch reaches the realm but /user_uploads/
;;    requires authentication: the anonymous fetch gets redirected to the
;;    login page, shr cannot decode HTML as an image, and the placeholder is
;;    again never replaced. The package knows how to authenticate
;;    (`zulip--api-auth-header'); the image request just never carries it.
;;
(defun zulip--insert-content-with-base (html)
  "Render message HTML like `zulip--insert-content', with a working base URL.
Wraps the DOM in a (base ((href . <server>))) node so shr can
absolutize the relative /user_uploads/ image URLs; see the comment
above for why let-binding `shr-base' (what upstream does) cannot work."
  (if (and zulip-render-html
           (fboundp 'libxml-parse-html-region))
      (let ((dom (with-temp-buffer
                   (insert html)
                   (libxml-parse-html-region (point-min) (point-max))))
            (server (and (bound-and-true-p zulip--current-connection)
                         (zulip--connection-server zulip--current-connection))))
        (zulip--dom-highlight-mentions dom)
        (let ((shr-use-fonts nil)
              (shr-width (min 80 (- (window-width) 4))))
          (shr-insert-document
           (if server (list 'base (list (cons 'href server)) dom) dom))))
    (insert (zulip--strip-html html))))
(with-eval-after-load 'zulip
  (advice-add 'zulip--insert-content :override
              #'zulip--insert-content-with-base))
;;
;; The header cannot be bound at render time -- url-queue runs the real
;; `url-retrieve' later from a timer -- but it runs it with the job's
;; context-buffer current, and that buffer is the zulip buffer holding the
;; buffer-local `zulip--current-connection'. So advise the (internal) runner:
;; when the job came from a zulip buffer AND its URL is on that connection's
;; realm, add the Basic-auth header. The URL check keeps the API key from ever
;; being sent to a foreign host (e.g. external image previews).
(defun zulip--auth-image-fetch (orig job)
  "Add realm API auth to url-queue JOBs requested from Zulip buffers."
  (let* ((ctx (url-queue-context-buffer job))
         (conn (and (buffer-live-p ctx)
                    (boundp 'zulip--current-connection)
                    (buffer-local-value 'zulip--current-connection ctx))))
    (if (and conn
             (string-prefix-p (zulip--connection-server conn)
                              (url-queue-url job)))
        (let ((url-request-extra-headers
               (cons (cons "Authorization" (zulip--api-auth-header conn))
                     url-request-extra-headers)))
          (funcall orig job))
      (funcall orig job))))
(with-eval-after-load 'zulip
  (require 'url-queue)
  (advice-add 'url-queue-start-retrieve :around #'zulip--auth-image-fetch))

;; url-queue kills any job 5 seconds after it starts (`url-queue-timeout') and
;; a killed image job also leaves the placeholder behind -- too tight for
;; downloading images over a slow link. (Safe as a plain setq: defcustom does
;; not clobber a value that is already set when url-queue loads later.)
(setq url-queue-timeout 30)
;;
;; `zulip-doom' in the same package registers SPC leader bindings for Doom
;; Emacs' evil setup; this is a vanilla config, so it is deliberately not loaded.
(global-set-key (kbd "C-c z") #'zulip-home)

;; --- Music (smudge / Spotify) ------------------------------------------------
;; Smudge controls Spotify from Emacs: playback, search, playlists, liked
;; songs, and a player-status segment in the mode line. Playback commands go
;; over a pluggable transport (`smudge-transport', default `connect' = the
;; Spotify Connect Web API, which needs a Premium account; flip it to `dbus'
;; to drive a locally running desktop client over MPRIS instead -- more
;; limited, but works without Premium). Everything else (search, playlists)
;; always goes over the Web API regardless of transport, and that needs an
;; OAuth app of your own: create one at
;; https://developer.spotify.com/dashboard with redirect URI
;; http://127.0.0.1:8080/smudge_api_callback, then put the client id and
;; secret in ~/.keys/spotify-client-id.txt and
;; ~/.keys/spotify-client-secret.txt (one value per file -- the same scheme
;; msmtprc's passwordeval uses; credentials never live in this repo). Missing
;; files must not break startup: the binding below still works, and
;; `smudge-bootstrap' just tells you what to set up.
(defun smudge--read-key-file (file)
  "Return the trimmed contents of FILE, or nil if it is not readable."
  (when (file-readable-p file)
    (string-trim
     (with-temp-buffer
       (insert-file-contents file)
       (buffer-string)))))
;; Plain setq before the package loads is safe for the same reason as
;; `url-queue-timeout' above: defcustom does not clobber an already-set value.
(let ((id     (smudge--read-key-file "~/.keys/spotify-client-id.txt"))
      (secret (smudge--read-key-file "~/.keys/spotify-client-secret.txt")))
  (when (and id secret)
    (setq smudge-oauth2-client-id id
          smudge-oauth2-client-secret secret)))

;; Keep a music client out of startup, like magit and zulip above. The search
;; commands carry autoload cookies, but the useful entry point is the command
;; keymap, and that cannot be autoloaded the obvious way: `smudge-command-map'
;; is a plain defvar, so its *value* is the keymap while key lookup follows a
;; symbol's *function* cell -- `(global-set-key (kbd "C-c s")
;; 'smudge-command-map)' would just error when pressed. Upstream's README
;; sidesteps this with use-package's :bind-keymap; this is what :bind-keymap
;; actually expands to: a stand-in command that loads the package, rebinds the
;; prefix to the real keymap (its value, now available), and replays the
;; pending prefix press via `set-transient-map' so even the very first
;; C-c s behaves like the real prefix (C-c s SPC plays/pauses, n/b skip,
;; t s searches tracks, p m lists playlists, d picks a device, ...).
;;
;; C-c s rather than upstream's suggested C-c .: that key is org-time-stamp,
;; and enabling smudge's own prefix machinery (`smudge-keymap-prefix') would
;; put it in a minor-mode map that shadows org's binding in every org-roam
;; buffer. A plain global binding on a free key stays out of every major
;; mode's way.
(defun smudge-bootstrap ()
  "Load smudge, hand C-c s over to `smudge-command-map', and start remote mode."
  (interactive)
  (require 'smudge)
  (global-set-key (kbd "C-c s") smudge-command-map)
  (set-transient-map smudge-command-map)
  (if (string-empty-p smudge-oauth2-client-id)
      (message "smudge: no Spotify app credentials in ~/.keys -- see the Music section of init.el")
    ;; The status timer polls every 5s; only start it once credentials exist,
    ;; or it would raise an OAuth error at every tick.
    (global-smudge-remote-mode 1)))
(global-set-key (kbd "C-c s") #'smudge-bootstrap)

;; Upstream guard: smudge's OAuth flow (`smudge-api-oauth2-auth', rewritten
;; upstream in early 2026) blocks Emacs in `(while ... (sleep-for 0.5))'
;; until the browser hits its 127.0.0.1:8080 callback -- and it binds
;; `inhibit-message', hiding even its own "Waiting..." hint, so a missed
;; browser tab or a redirect-URI mismatch in the Spotify dashboard looks like
;; a plain freeze with no way out. Worse, C-g out of that wait leaves
;; `smudge-api-oauth2-auth-in-progress' stuck at t, and the remote-mode poll
;; timer then re-freezes Emacs every 5s in a *second* loop that spins on that
;; flag forever. The advice below makes the flow survivable: say what is
;; being waited on, and on timeout (120s covers a login + consent
;; round-trip), C-g, or error, reset the state flags, stop the callback
;; server, and turn the poll mode back off so nothing silently retries.
;; `with-timeout' works here because timers fire inside `sleep-for' (verified
;; -- the same mechanism smudge's own callback server relies on). Remove this
;; if upstream ever bounds the wait and clears the flag on abort itself.
(defun smudge--auth-abort (why)
  "Clean up after a failed smudge OAuth attempt, explaining WHY.  Return nil."
  (setq smudge-api-oauth2-auth-code nil
        smudge-api-oauth2-callback-state nil
        smudge-api-oauth2-auth-in-progress nil)
  (ignore-errors (smudge-api-oauth2-stop-server))
  (when (bound-and-true-p global-smudge-remote-mode)
    (global-smudge-remote-mode -1))
  (message "smudge: authorization %s -- check the browser tab and the app's redirect URI, then retry C-c s" why)
  nil)

(defun smudge--auth-bounded (orig &rest args)
  "Run ORIG (smudge's blocking OAuth flow) with a timeout and C-g/error cleanup."
  (message "smudge: waiting for Spotify authorization in your browser (C-g aborts)...")
  (condition-case err
      (with-timeout (120 (smudge--auth-abort "timed out"))
        (apply orig args))
    (quit (smudge--auth-abort "was quit"))
    (error (smudge--auth-abort (error-message-string err))
           (signal (car err) (cdr err)))))

(with-eval-after-load 'smudge-api
  (advice-add 'smudge-api-oauth2-auth :around #'smudge--auth-bounded))

;; --- direnv (envrc) ----------------------------------------------------------
;; Buffer-local direnv integration: a buffer inside a project with an allowed
;; .envrc gets that project's environment (PATH, VIRTUAL_ENV, ...) without
;; leaking it anywhere else, so two projects with different venvs can be open
;; at once and each LSP/flymake/compile sees its own tools. Guarded on the
;; binary like Air: machines without direnv (`sudo dnf install direnv') no-op.
;; Deliberately the LAST global mode in this file -- envrc's README asks for
;; that, because each global minor mode prepends itself to find-file hooks and
;; envrc must run before the others to have the environment in place.
(when (executable-find "direnv")
  (envrc-global-mode 1))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("e0c071f25577ed64d63ab0a77f032ff401e3b362aa126b8a4e0b09a18c310cd4"
     "e5957c6c57f6e325d6a0f4d6dfabdc4377457a4cd626f44f8bc6084396b5b3cf"
     "e7e15acc1ebe548c76270deb1b03110968acbea74c3046bf1c79d6501c7e7807"
     "de8106f57663c5966684ec4dd4e57028491fd27d8a382d386a58814cf5a3cf66"
     "48a575111485ab285e07ca63f064e0ae453dc8ed06d965e0d73fe29d35e607dd"
     "f60c23f2a3bcd3ac79c5ff8435395cf5dbb8117d88db0ec54b6578e08a7c85cd"
     "b6dbc7d44b4f6d4f6d1ae6d340053ed398dea44a4725841979b0a5542cdd0481"
     "672539b07026a12ce91c3e23b9aa1ad4edbdc5096b279003bb504a9399898c81"
     "be551d30fbecf76a401a021d5161f7d1b0c9153eb6c9ab8e3d40564ce649315f"
     "a8c1252f9844caf313a2315ecf1e8ef4d92495c9f2067d875bb1c783b08719ad"
     "2b0fcc7cc9be4c09ec5c75405260a85e41691abb1ee28d29fcd5521e4fca575b"
     "615d8f3208b19161ada77e155beaca0678a35abb182ceae87e26660ecbca04d5"
     "d5c1a09648941993271f1961b4de2801622eea54fb95ce4b2df2fd55d426e52c"
     "0d2c5679b6d087686dcfd4d7e57ed8e8aedcccc7f1a478cd69704c02e4ee36fe"
     "e1df746a4fa8ab920aafb96c39cd0ab0f1bac558eff34532f453bd32c687b9d6"
     "5cb84685a211fb46e47ca355dc91e52adf0c185dc0603cfe27c63855f200dd1f"
     "7771c8496c10162220af0ca7b7e61459cb42d18c35ce272a63461c0fc1336015"
     "aec7b55f2a13307a55517fdf08438863d694550565dee23181d2ebd973ebd6b8"
     "456697e914823ee45365b843c89fbc79191fdbaff471b29aad9dcbe0ee1d5641"
     "f64189544da6f16bab285747d04a92bd57c7e7813d8c24c30f382f087d460a33"
     "f053f92735d6d238461da8512b9c071a5ce3b9d972501f7a5e6682a90bf29725"
     "dd4582661a1c6b865a33b89312c97a13a3885dc95992e2e5fc57456b4c545176"
     "2b0531a540f4b51e524f551ed7374099f9d743b4de458ade0c52ba18ee6bfe46"
     "9b9d7a851a8e26f294e778e02c8df25c8a3b15170e6f9fd6965ac5f2544ef2a9"
     "4b88b7ca61eb48bb22e2a4b589be66ba31ba805860db9ed51b4c484f3ef612a7"
     "70c88c01b0b5fde9ecf3bb23d542acba45bb4c5ae0c1330b965def2b6ce6fac3"
     "599f72b66933ea8ba6fce3ae9e5e0b4e00311c2cbf01a6f46ac789227803dd96"
     "5c7720c63b729140ed88cf35413f36c728ab7c70f8cd8422d9ee1cedeb618de5"
     "7de64ff2bb2f94d7679a7e9019e23c3bf1a6a04ba54341c36e7cf2d2e56e2bcc"
     "720838034f1dd3b3da66f6bd4d053ee67c93a747b219d1c546c41c4e425daf93"
     "fffef514346b2a43900e1c7ea2bc7d84cbdd4aa66c1b51946aade4b8d343b55a"
     "833ddce3314a4e28411edf3c6efde468f6f2616fc31e17a62587d6a9255f4633"
     "df6dfd55673f40364b1970440f0b0cb8ba7149282cf415b81aaad2d98b0f0290"
     "f76e34f676ac1fbce608c5f38033c35e370509619b9a3acd02a518ef58b01107"
     "b7a09eb77a1e9b98cafba8ef1bd58871f91958538f6671b22976ea38c2580755"
     "f1e8339b04aef8f145dd4782d03499d9d716fdc0361319411ac2efc603249326"
     "acd363510d3e4b638db178783bde3d4492574c0f5c889f845251949f43567d16"
     "d97ac0baa0b67be4f7523795621ea5096939a47e8b46378f79e78846e0e4ad3d"
     "7fea145741b3ca719ae45e6533ad1f49b2a43bf199d9afaee5b6135fd9e6f9b8"
     "088cd6f894494ac3d4ff67b794467c2aa1e3713453805b93a8bcb2d72a0d1b53"
     "0f1341c0096825b1e5d8f2ed90996025a0d013a0978677956a9e61408fcd2c77"
     "4594d6b9753691142f02e67b8eb0fda7d12f6cc9f1299a49b819312d6addad1d"
     default))
 '(org-agenda-files
   '("/home/simon/org-mode/agenda/invites.org"
     "/home/simon/org-mode/agenda/index.org"
     "/home/simon/org-mode/agenda/routines.org"
     "/home/simon/org-mode/agenda/workload.org"
     "/home/simon/org-mode/areas/career/goals.org"
     "/home/simon/org-mode/areas/career/index.org"
     "/home/simon/org-mode/areas/career/positioning_choices.org"
     "/home/simon/org-mode/areas/development/index.org"
     "/home/simon/org-mode/areas/outreach/index.org"
     "/home/simon/org-mode/areas/research/conferences/2026_season.org"
     "/home/simon/org-mode/areas/research/funding/opportunities/digest/20260124.org"
     "/home/simon/org-mode/areas/research/funding/opportunities/brazil_uk.org"
     "/home/simon/org-mode/areas/research/funding/opportunities/esrc_grants.org"
     "/home/simon/org-mode/areas/research/funding/opportunities/esrc_secondarydata.org"
     "/home/simon/org-mode/areas/research/funding/opportunities/isambard_gateway.org"
     "/home/simon/org-mode/areas/research/funding/opportunities/isambard_rapid.org"
     "/home/simon/org-mode/areas/research/funding/opportunities/lt.org"
     "/home/simon/org-mode/areas/research/funding/opportunities/metascience.org"
     "/home/simon/org-mode/areas/research/funding/opportunities/p2r.org"
     "/home/simon/org-mode/areas/research/funding/opportunities/switzerland.org"
     "/home/simon/org-mode/areas/research/funding/index.org"
     "/home/simon/org-mode/areas/research/streams/index.org"
     "/home/simon/org-mode/areas/research/streams/labor_division.org"
     "/home/simon/org-mode/areas/research/streams/language_and_organizing.org"
     "/home/simon/org-mode/areas/research/streams/methods.org"
     "/home/simon/org-mode/areas/research/index.org"
     "/home/simon/org-mode/areas/supervision/alfredo.org"
     "/home/simon/org-mode/areas/supervision/ben.org"
     "/home/simon/org-mode/areas/supervision/derek.org"
     "/home/simon/org-mode/areas/supervision/index.org"
     "/home/simon/org-mode/areas/supervision/joseph.org"
     "/home/simon/org-mode/areas/supervision/kabir.org"
     "/home/simon/org-mode/areas/supervision/matteo.org"
     "/home/simon/org-mode/travel/index.org"))
 '(package-selected-packages
   '(all-the-icons all-the-icons-dired cape casual citar citar-org-roam
		   claude-code-ide compat consult consult-lsp corfu
		   csv-mode dap-mode darkroom diff-hl dired-sidebar
		   doom-modeline doom-themes ef-themes eldoc-box
		   emacs-codex-ide emacs-zulip embark embark-consult
		   envrc ess exec-path-from-shell
		   gnu-elpa-keyring-update insert-uuid julia-mode
		   lsp-mode lsp-pyright magit marginalia markdown-mode
		   markdown-toc mermaid-mode minions nerd-icons
		   ob-mermaid olivetti orderless org-roam
		   org-roam-bibtex org-roam-ql org-roam-ui org-sidebar
		   pdf-tools quarto-mode rainbow-csv
		   rainbow-delimiters reformatter smudge
		   solarized-theme vertico vterm writeroom-mode
		   yasnippet yasnippet-capf yasnippet-snippets))
 '(package-vc-selected-packages
   '((insert-uuid :vc-backend Git :url
		  "https://github.com/theesfeld/insert-uuid")
     (emacs-zulip :vc-backend Git :url
		  "https://github.com/suky57/emacs-zulip")
     (rainbow-csv :vc-backend Git :url
		  "https://github.com/emacs-vs/rainbow-csv")
     (emacs-codex-ide :vc-backend Git :url
		      "https://github.com/dgillis/emacs-codex-ide")
     (claude-code-ide :vc-backend Git :url
		      "https://github.com/manzaltu/claude-code-ide.el")))
 '(safe-local-variable-directories '("/home/simon/org-mode/"))
 '(safe-local-variable-values
   '((org-use-property-inheritance . t) (org-log-into-drawer . "LOGBOOK")
     (org-log-done . time) (org-startup-indented . t)
     (org-startup-folded . content))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
