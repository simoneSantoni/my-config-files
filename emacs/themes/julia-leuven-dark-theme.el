;;; julia-leuven-dark-theme.el --- Julia colours, Leuven typography -*- lexical-binding: t; -*-
;; SPDX-License-Identifier: GPL-3.0-or-later
(deftheme julia-leuven-dark "Julia's four colours on a charcoal background.")
(load (expand-file-name "julia-leuven-common.el"
                        (file-name-directory (or load-file-name buffer-file-name)))
      nil t)
(julia-leuven--define 'julia-leuven-dark t)
(provide-theme 'julia-leuven-dark)
