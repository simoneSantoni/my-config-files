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
                           sqlite3
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
                  insert-uuid mathpix))))

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
;; ~/org-mode/.dir-locals.el sets per-file org behavior (folding, logging,
;; property inheritance) for the whole notes repo. Those variables carry no
;; `safe-local-variable' predicate upstream, so visiting any note fires the
;; "values that may not be safe" prompt. Whitelist the exact value pairs here
;; instead of answering `!' in the prompt, which would grow the Custom-owned
;; block at the end of this file. Value pairs, not blanket trust: if the
;; .dir-locals.el changes, the prompt returns and the new value gets reviewed.
(dolist (pair '((org-startup-folded . content)
                (org-startup-indented . t)
                (org-log-done . time)
                (org-log-into-drawer . "LOGBOOK")
                (org-use-property-inheritance . t)))
  (add-to-list 'safe-local-variable-values pair))

;; --- Calendar <-> org agenda -------------------------------------------------
;; The agenda itself is configured inside the org repo
;; (~/org-mode/org-config.el: `org-agenda-files', capture templates, refile,
;; todo keywords) so it travels with the notes, not with this machine's Emacs.
;; Until now that file only loaded when loaded by hand, which was fine for
;; editing org files but useless for a calendar that should always know what
;; the agenda holds. Load it at startup when the repo is present; guarded so a
;; machine without the repo still boots (same policy as mu4e). org is already
;; loaded above (org-roam) and the file requires org-agenda itself, so the
;; real cost is just its recursive scan of the repo's org files.
(let ((org-repo-config (expand-file-name "~/org-mode/org-config.el")))
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
  (let* ((day (or (and (boundp 'org-agenda-current-date) org-agenda-current-date)
                  (and (boundp 'date) (symbol-value 'date))))
         (holidays (and (consp day) (calendar-check-holidays day))))
    (and holidays (mapconcat #'identity holidays "; "))))
(unless (file-exists-p diary-file)
  (with-temp-file diary-file
    (insert "&%%(os-diary-holiday-entry)\n&%%(org-diary)\n")))
(setq org-agenda-include-diary t)
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
;;                ~/org-mode/org-config.el and its mid-session refresh advice);
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
(autoload 'calfw-open-calendar-buffer "calfw" nil t)
(autoload 'calfw-org-create-source "calfw-org")
(autoload 'calfw-cal-create-source "calfw-cal")
(defun os-calfw-open ()
  "Open a calfw month grid showing org agenda entries and diary entries."
  (interactive)
  (require 'calfw-org)
  (require 'calfw-cal)
  (calfw-open-calendar-buffer
   ;; nil org-files = whatever `org-agenda-files' holds when the grid is
   ;; built, so the mid-session refresh advice in org-config.el is honoured.
   :contents-sources (list (calfw-org-create-source nil "org" "SteelBlue")
                           (calfw-cal-create-source "diary" "ForestGreen"))
   :view 'month
   :sorter #'calfw-org--schedule-sorter))
;; `C-c v' for *v*iew, not `C-c c': the org manual reserves that one for
;; `org-capture', and ~/org-mode/org-config.el already defines the templates
;; it would run.
(global-set-key (kbd "C-c v") #'os-calfw-open)

;; --- Bibliography, graph, and node queries ----------------------------------
;; Four things layered on org-roam, all from MELPA:
;;   citar + citar-org-roam -- a completion UI over the .bib for org-cite, with
;;                             org-roam nodes standing in as the note store;
;;   org-roam-bibtex        -- capture templates and attachment handling keyed
;;                             by citekey, plus `orb-insert-link';
;;   org-roam-ui            -- the node graph, served to a browser;
;;   org-roam-ql            -- a query language over the node database.
;;
;; This block deliberately sits after ~/org-mode/org-config.el is loaded above.
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
;; `bibtex-completion-bibliography' -- set by ~/org-mode/org-config.el, same as
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

;; Appearance: a slightly taller bar breathes better at this font size, and
;; the hud draws a mini indicator of the window's position in the buffer in
;; place of the plain bar.
(setq doom-modeline-height 28)
(setq doom-modeline-hud t)

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

;; --- Themes (ef-themes + leuven + solarized + doom-themes) -------------------
;; Only one theme is ever active, and `ef-elea-light' below is it: the light half
;; of Protesilaos' Elea pair, a warm green-tinted background with the org
;; typography set up further down. `leuven' -- Fabrice Niessen's light theme,
;; which ships *with Emacs* (etc/themes/leuven-theme.el), so it needs no package,
;; no entry in `required-packages' and nothing installed, the built-in themes
;; directory already being the `t' element of `custom-theme-load-path' -- is the
;; fallback that the org styling below is modelled on. Its companion
;; `leuven-dark' is bundled too.
;;
;; The three installed theme *packs* are here to switch to with M-x load-theme,
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
;;                       active pack. M-x ef-themes-select, or ef-themes-toggle
;;                       for the pair named in `ef-themes-to-toggle' below; the
;;                       `require' is what makes that pair, the heading styles
;;                       and the palette overrides below all take effect before
;;                       the theme is loaded at the end of this section.
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
;; end of this file used to carry `custom-enabled-themes', which runs later and
;; would override whatever is loaded here (see the note there).
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
;;
;; The graphics check has to run per-buffer, not at init: under `emacs
;; --daemon' no frame exists while init runs, so a top-level
;; `display-graphic-p' is nil and GUI frames created later would silently
;; never get the popup. Deciding inside the hook tests the frame the buffer
;; actually appears on. And since lsp-mode publishes its hover docs through
;; eldoc exactly as eglot does, hook both clients -- Python/Julia/R buffers
;; get the same popup as TeX.
(defun my-eldoc-box-enable-if-graphic ()
  "Enable `eldoc-box-hover-at-point-mode' on graphical frames only."
  (when (display-graphic-p)
    (eldoc-box-hover-at-point-mode 1)))
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
(add-hook 'julia-mode-hook #'julia-repl-mode)
(with-eval-after-load 'julia-repl
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
        "~/org-mode/agenda/invites.org")
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

;; Jump-to-folder shortcuts (the `j' command in the headers/main view). Every
;; maildir OfflineIMAP syncs gets a key, so this list mirrors the Gmail label
;; set; add a line here when a new label appears. `training' and `sociology'
;; are real labels that may be empty inside the 30-day `maxage' window.
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
        (:maildir "/gmail/sociology"         :key ?z)))

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
 '(custom-enabled-themes '(leuven))
 '(custom-safe-themes
   '("df6dfd55673f40364b1970440f0b0cb8ba7149282cf415b81aaad2d98b0f0290"
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
		   solarized-theme sqlite3 vertico vterm
		   writeroom-mode yasnippet yasnippet-capf
		   yasnippet-snippets))
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
