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
                           all-the-icons
                           ef-themes
                           solarized-theme
                           doom-themes
                           magit
                           diff-hl
                           lsp-mode
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
                           ess
                           reformatter
                           quarto-mode
                           rainbow-delimiters
                           sqlite3
                           org-roam
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
                  dired-sidebar org-sidebar all-the-icons-dired))))

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

;; --- File sidebar -----------------------------------------------------------
;; A lightweight project/file tree backed by Dired. Keep it autoloaded so it
;; adds no startup work until the sidebar is first opened.
(setq dired-sidebar-theme 'nerd-icons)
(global-set-key (kbd "C-x C-n") #'dired-sidebar-toggle-sidebar)
(add-hook 'dired-mode-hook #'all-the-icons-dired-mode)

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
;; The knowledge base is the whole academic organization repo: every active
;; org file there carries a file-level ID and is an org-roam node. The db
;; lives inside the repo (dot-file, gitignored) so the index travels with it.
(setq org-roam-directory (expand-file-name "~/org-mode"))
(setq org-roam-db-location (expand-file-name "~/org-mode/.org-roam.db"))
;; Keep archived/binary trees out of the node list, mirroring the exclusions
;; org-config.el applies to `org-agenda-files'. Lock files (.#foo.org) too.
(setq org-roam-file-exclude-regexp '("archive/" "attachments/" "cv/" "\\.#"))
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
;; Org sidebars: task overview and navigable outline tree, respectively.
(global-set-key (kbd "C-c n s") #'org-sidebar-toggle)
(global-set-key (kbd "C-c n t") #'org-sidebar-tree-toggle)

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
  ;; The default field list with :attach slotted in after the flags.
  (setq mu4e-headers-fields
        '((:human-date . 12)
          (:flags . 6)
          (:attach . 2)
          (:mailing-list . 10)
          (:from . 22)
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
        "~/org-mode/agenda/imports/invites.org")
  (setq gnus-icalendar-org-capture-headline '("Invitations"))
  (gnus-icalendar-org-setup)
  ;; Duplicate-protection depends on the capture file being findable: the
  ;; export button looks the event's UID up in `org-agenda-files' and only
  ;; offers "Update Org Entry" when found. The org repo's org-config.el sets
  ;; org-agenda-files, but only in sessions that loaded it -- in a mail-only
  ;; session the variable is empty, every press appends a fresh duplicate,
  ;; and the button never changes label. Registering the capture file here
  ;; keeps lookups working everywhere; when org-config.el loads it rebuilds
  ;; the list wholesale and picks this file up again via its agenda/ scan.
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

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("088cd6f894494ac3d4ff67b794467c2aa1e3713453805b93a8bcb2d72a0d1b53"
     "0f1341c0096825b1e5d8f2ed90996025a0d013a0978677956a9e61408fcd2c77"
     "4594d6b9753691142f02e67b8eb0fda7d12f6cc9f1299a49b819312d6addad1d"
     default))
 '(package-vc-selected-packages
   '((emacs-zulip :vc-backend Git :url
		  "https://github.com/suky57/emacs-zulip")
     (rainbow-csv :vc-backend Git :url
		  "https://github.com/emacs-vs/rainbow-csv")
     (emacs-codex-ide :vc-backend Git :url
		      "https://github.com/dgillis/emacs-codex-ide")
     (claude-code-ide :vc-backend Git :url
		      "https://github.com/manzaltu/claude-code-ide.el")))
 '(safe-local-variable-directories '("/home/simon/org-mode/")))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
