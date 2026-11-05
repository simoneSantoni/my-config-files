;;; julia-leuven-common.el --- Julia palette over Leuven -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Commentary:
;; Keep Leuven's extensive package coverage, face inheritance, Sans Serif mail
;; headers, scaled titles and heading weights.  Recolour its face specifications
;; rather than enabling a second theme: disabling this theme then restores faces
;; normally.  Accumulate one spec per face before registering: while loading
;; a disabled theme, repeated custom-theme-set-faces calls can append duplicate
;; settings, and enabling it then lets the inherited spec overwrite our override.
;; Source palette: https://github.com/JuliaLang/julia-logo-graphics
;; Blue #4063D8, green #389826, red #CB3C33, purple #9558B2.
;; Accent roles incorporate the requested blue/red, then red/green swaps:
;; keywords/functions use green, strings use red, constants/errors use blue.
;; All four accents also appear in ordinary Org documents without requiring
;; four nested headings: purple titles/tags, green top headings and completed
;; tasks, red drawers and open tasks, blue links/tables.  Explicit Org faces
;; keep this balance independent of Leuven's inherited decorative colour
;; mapping.
;; Light text colours darken green for legibility; dark colours are lifted.
;; The optional green light variant uses Julia green #389826 mixed with 93% white (#f1f8f0,
;; rounded to 8-bit channels); its neutral surfaces use a slightly stronger
;; green wash (#e7f2e5).  Keep the paper almost white so all four foreground
;; accents remain distinct, while code blocks and the mode-line have depth.
;; All background tints come from those same four hues.  No font is installed
;; or forced globally: Leuven's Sans Serif variations and the user's fixed-pitch
;; font (JuliaMono in this configuration) remain available on every platform.
;;; Code:
(require 'color)
(require 'cl-lib)

(defun julia-leuven--define (theme dark &optional green-paper)
  "Populate THEME from Leuven.
DARK selects the dark palette; GREEN-PAPER tints the light background green."
  (unless (custom-theme-p 'leuven) (load-theme 'leuven t t))
  (let* ((bg (cond (dark "#1e2028") (green-paper "#f1f8f0") (t "#ffffff")))
         (fg (if dark "#e3e4ec" "#282936"))
         (muted (if dark "#a1a5b6" "#656979"))
         (surface (cond (dark "#292d39") (green-paper "#e7f2e5")
                        (t "#f1f3f8")))
         (blue (if dark "#96adff" "#4063d8"))
         (green (if dark "#8bd17c" "#287522"))
         (red (if dark "#ff968c" "#cb3c33"))
         (purple (if dark "#ce9de5" "#9558b2"))
         (accents (list green red blue purple))
         (faces nil))
    (cl-labels
        ((tint (c) (apply #'color-rgb-to-hex
                         (append (cl-mapcar (lambda (a b) (+ (* .14 a) (* .86 b)))
                                            (color-name-to-rgb c)
                                            (color-name-to-rgb bg)) '(2))))
         (recolour (value background)
           (if (not (and (stringp value) (color-name-to-rgb value))) value
             (pcase-let* ((`(,r ,g ,b) (color-name-to-rgb value))
                          (`(,h ,s ,v) (color-rgb-to-hsv r g b)))
               (if (< s .12)
                   (if background (if (> v .97) bg surface)
                     (if (< v .3) fg muted))
                 (let ((accent (cond ((or (< h .08) (> h .94)) blue)
                                     ((< h .19) purple)
                                     ((< h .46) red)
                                     ((< h .72) green) (t purple))))
                   (if background (tint accent) accent))))))
         (walk (tree &optional background)
           (cond ((null tree) nil)
                 ((consp tree)
                  (if (keywordp (car tree))
                      (cons (car tree)
                            (cons (walk (cadr tree) (eq (car tree) :background))
                                  (walk (cddr tree) background)))
                    (cons (walk (car tree) background)
                          (walk (cdr tree) background))))
                 (t (recolour tree background))))
         (face (name &rest props)
           (setf (alist-get name faces) `((t ,@props)))))
      (dolist (setting (get 'leuven 'theme-settings))
        (when (eq (car setting) 'theme-face)
          (setf (alist-get (nth 1 setting) faces)
                (walk (nth 3 setting)))))
      ;; Explicit semantic anchors prevent the inherited theme's decorative
      ;; colours from changing syntax roles or status meanings.
      ;; Terminal output uses ANSI faces rather than font-lock.  Mirror the
      ;; Ghostty palette and the requested accent swaps, with both foreground
      ;; and background defined because vterm queries each independently.
      (cl-loop for suffix in '(black red green yellow blue magenta cyan white
                               bright-black bright-red bright-green bright-yellow
                               bright-blue bright-magenta bright-cyan bright-white)
               for colour in (append
                              (list (if dark surface fg) blue red purple green
                                    purple green (if dark fg surface))
                              (if dark
                                  '("#a1a5b6" "#b8c7ff" "#ffb7af" "#e2bff1"
                                    "#afe49f" "#dcb3ee" "#a4dca2" "#ffffff")
                                (list muted "#304eb8" "#a82f29" "#78418f"
                                      "#205f1b" "#80459d" "#246820" "#ffffff")))
               do (dolist (prefix '(term-color- vterm-color-))
                    (face (intern (format "%s%s" prefix suffix))
                          :foreground colour :background colour)))
      (face 'default :foreground fg :background bg)
      (face 'cursor :background purple)
      (face 'fringe :background bg :foreground muted)
      (face 'region :background (tint green) :foreground fg :extend t)
      (face 'font-lock-keyword-face :foreground green)
      (face 'font-lock-function-name-face :foreground green)
      (face 'font-lock-type-face :foreground purple)
      (face 'font-lock-variable-name-face :foreground purple)
      (face 'font-lock-string-face :foreground red)
      (face 'font-lock-doc-face :foreground red)
      (face 'font-lock-constant-face :foreground blue)
      (face 'font-lock-comment-face :foreground muted :slant 'italic)
      (face 'font-lock-comment-delimiter-face :foreground muted)
      (face 'success :foreground red :weight 'bold)
      (face 'warning :foreground purple :weight 'bold)
      (face 'error :foreground blue :weight 'bold)
      ;; Light variants use a slightly deeper purple active bar with dark text.  The dark variant's
      ;; active bar uses the original Julia purple with light text, while its
      ;; inactive bar retains the light gray surface and dark text.  Leave
      ;; Doom's base foreground unspecified there so its per-window active/
      ;; inactive inheritance can select the appropriate text colour.
      (face 'mode-line :foreground (if dark "#f7f0fa" "#282936")
            :background (if dark "#9558b2" "#e6d6ed")
            :box `(:line-width 1 :color ,purple))
      (face 'mode-line-inactive :foreground "#282936" :background "#eeeeee"
            :box `(:line-width 1 :color ,muted))
      (face 'mode-line-buffer-id :foreground (if dark "#f7f0fa" "#287522")
            :weight 'bold)
      (face 'mode-line-emphasis :foreground (if dark "#f7f0fa" "#9558b2")
            :weight 'bold)
      (face 'doom-modeline :foreground (if dark 'unspecified "#282936"))
      ;; Doom draws the separator from this face's background, independently
      ;; of the modeline border.  Match the active purple and inactive gray.
      (face 'doom-modeline-bar :background purple)
      (face 'doom-modeline-bar-inactive :background muted)
      (face 'org-document-title :foreground purple :weight 'bold :height 1.8)
      (face 'org-document-info :foreground purple)
      (face 'org-document-info-keyword :foreground purple
            :background (tint purple))
      (face 'org-meta-line :foreground muted)
      (face 'org-drawer :foreground red :background (tint red))
      (face 'org-property-value :foreground red)
      (face 'org-special-keyword :foreground red)
      (face 'org-tag :foreground purple :weight 'normal)
      (face 'org-table :foreground blue :inherit 'fixed-pitch)
      (face 'org-date :foreground purple :underline t)
      (face 'org-link :foreground blue :underline t)
      (face 'link :foreground blue :underline t)
      (face 'org-block-begin-line :foreground red :background surface :extend t)
      (face 'org-block-end-line :foreground red :background surface :extend t)
      (face 'org-agenda-structure :foreground purple :weight 'bold :height 1.3)
      (face 'org-agenda-date :foreground blue :weight 'bold)
      (face 'org-agenda-date-today :foreground green :weight 'bold)
      (face 'minibuffer-prompt :foreground purple :weight 'bold)
      (face 'show-paren-match :foreground red :background (tint red)
            :weight 'bold)
      (face 'isearch :foreground purple :background (tint purple) :weight 'bold)
      (face 'org-block :inherit 'fixed-pitch :background surface :foreground fg
            :extend t)
      (face 'org-code :inherit 'fixed-pitch :foreground red)
      (face 'org-verbatim :inherit 'fixed-pitch :foreground purple)
      (face 'org-todo :foreground red :background (tint red) :weight 'bold)
      (face 'org-done :foreground green :background (tint green) :weight 'bold)
      (cl-loop for name in '(os-org-todo-next os-org-todo-wait os-org-todo-hold
                            os-org-todo-cancelled)
               for colour in (list green blue purple muted)
               do (face name :foreground colour :weight 'bold))
      (cl-loop for level from 1 to 8
               for colour = (nth (% (1- level) 4) accents)
               do (dolist (prefix '(org-level- outline-))
                    (apply #'face (intern (format "%s%d" prefix level))
                           (append (list :foreground colour :weight 'bold
                                         :height (if (= level 1) 1.3 1.0)
                                         :background (if (<= level 3)
                                                         (tint colour) bg)
                                         :extend t)
                                   (when (<= level 2)
                                     (list :overline colour))))))
      (apply #'custom-theme-set-faces theme
             (mapcar (lambda (entry) (list (car entry) (cdr entry))) faces)))))
(provide 'julia-leuven-common)
;;; julia-leuven-common.el ends here
