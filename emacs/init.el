;; Force the GUI toolbar to show icon images rather than text labels.
;; This GTK3 build otherwise inherits the desktop's
;; org.gnome.desktop.interface toolbar-style ('text'), which made the
;; toolbar render icon descriptions instead of icon pictures.
(setq tool-bar-style 'image)

;; Package archives: add MELPA alongside the default GNU/NonGNU ELPA.
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; On first run (or when the archive cache is empty), refresh package metadata
;; so M-x package-install / package-list-packages can see MELPA packages.
(unless package-archive-contents
  (package-refresh-contents))

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

;; --- vterm ------------------------------------------------------------------
;; Fully-featured terminal emulator backed by a native module. The module is
;; compiled on first load and needs cmake + libtool installed on the system.
(require 'vterm)

;; --- claude-code-ide --------------------------------------------------------
;; Runs the Claude Code CLI inside a vterm buffer with IDE integration.
(require 'claude-code-ide)

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

;; --- ef-themes --------------------------------------------------------------
;; Protesilaos' legible light/dark themes. Load one to activate; pick with
;; M-x ef-themes-select, or toggle a light/dark pair with M-x ef-themes-toggle.
(require 'ef-themes)
(setq ef-themes-to-toggle '(ef-light ef-dark))
(load-theme 'ef-light :no-confirm)

;; --- Default font -----------------------------------------------------------
;; JuliaMono Nerd Font Mono (includes Nerd Font glyphs/icons). Applies to the
;; current and all future frames.
(set-face-attribute 'default nil :family "JuliaMono Nerd Font Mono" :height 120)
(add-to-list 'default-frame-alist '(font . "JuliaMono Nerd Font Mono-12"))
