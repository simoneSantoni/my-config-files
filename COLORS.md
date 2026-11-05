# Colour scheme: leuven-dark, as configured

The dark scheme of **VS Code**, set up in **Emacs** as the alternative to its
active ef-elea-light, with a port kept as an alternative **Ghostty** theme
(Ghostty runs ef-elea-light too). It starts from
Fabrice Niessen's `leuven-dark`, which ships with GNU Emacs 30.2
(`/usr/share/emacs/30.2/etc/themes/leuven-dark-theme.el`, GPL-3.0-or-later),
and changes it where the shipped theme is illegible or ambiguous.

| Application | Where the colours live |
|---|---|
| Emacs | the bundled theme, plus the `os-leuven-dark-*` functions in `emacs/init.el` (themes section; not the active theme, select it at the end of that section) |
| Ghostty | `ghostty/themes/leuven-dark` (not the active theme; select it in `ghostty/config.ghostty`) |
| VS Code | `~/leuven-for-vscode` (a separate repo, symlinked into `~/.vscode/extensions/`), theme *Leuven Dark* |

**Source of truth.** `emacs/init.el` comes first, then the shipped theme. The
Ghostty and VS Code themes are ports of what Emacs actually shows, so change a
colour in Emacs first, then follow [Changing a colour](#changing-a-colour).

The other two schemes in this repo, Ubuntu Yaru and ef-elea-light, are
summarised in [`README.md`](README.md#theme).

All contrast ratios below are WCAG ratios against the background `#25202a`
unless stated otherwise. "On hl-line" means against the current-line
highlight `#2d2058`.

## Design rules

These are the reasons behind the overrides. Follow them when adding a colour.

1. **leuven-dark is leuven with every hue rotated.** Its syntax colours are
   fine, but colours whose *meaning* is their hue came out wrong: the shipped
   `error` is cyan, `success` magenta, `warning` dark blue, and the ANSI "red"
   is cyan. Emacs mostly keeps the shipped hues (it is the reference). The
   terminal palette and VS Code's diagnostics and diffs use conventional hues
   instead, picked from leuven-dark's own colours. See
   [Status colours](#status-colours).
2. **Contrast targets.** Body text is 10:1. Anything meant to be read is at
   least 4.5:1, except deliberately receding text (`shadow`, 4.1:1).
   Comments recede but stay readable at 5.5:1.
3. **Filled chips are rare on purpose.** Dark `#25202a` text on a bright fill
   is the loudest shape in the scheme. It is used only for Org task keywords,
   the selected completion candidate, and the minibuffer prompt.
4. **Bright fills use `:inverse-video`.** `hl-line` is an overlay, and an
   overlay's background replaces a text-property face's background. A plain
   yellow background therefore vanished on the cursor line. Chips set their
   colour as the *foreground* with `:inverse-video t`, so an overlay
   background only lands in the text slot. The same trick lets match faces
   become coloured patches on the selected vertico row.
5. **Bands carry light text.** A heading band is the full colour mixed into
   the background, with white text. Dark text on a band would also vanish
   under `hl-line`.
6. **Each hue keeps one meaning:**

   | Hue | Means |
   |---|---|
   | yellow `#ffff0b` | keywords, TODO, level-2 headings, the selected candidate |
   | cyan `#06ffff` | level-1 headings, and "what you searched for" (matches) |
   | SeaGreen3 `#43cd80` | the cursor, DONE, the minibuffer prompt |
   | burnt orange `#752c0b` | the region (selection) |
   | blue-violet `#2d2058` | the current line |
   | brown `#3c312a` + tan `#cfa161` | the mode-line / status bar |

## Base palette

| Role | Colour | Contrast | Emacs face | Ghostty | VS Code |
|---|---|---|---|---|---|
| Background | `#25202a` | — | `default` | `background` | `editor.background` |
| Foreground | `#cfccd2` | 10.0 | `default` | `foreground` | `editor.foreground` |
| Bright text | `#ffffff` | 15.9 | `mode-line-buffer-id`, level-1 heading | slot 15 | active tab |
| Surface | `#322d37` | — | (theme panels) | — | title bar, tabs, activity bar |
| Current line | `#2d2058` | — | `hl-line` | — | `editor.lineHighlightBackground` |
| Region | `#752c0b` | fg 6.2, white 9.9 | `region` | `selection-background` | `editor.selectionBackground` |
| Highlight | `#3c312a` | fg 7.9 | `highlight`, `mode-line` | — | `statusBar.background` |
| Tan accent | `#cfa161` | — | `mode-line` box | — | status bar border, focus borders |
| Shadow | `#848088` | 4.1 | `shadow` | slot 8 | inactive text |
| Comment | `#9a969e` | 5.5 | `font-lock-comment-face` ¹ | — | `comment` |
| Cursor | `#43cd80` | 7.8 (7.0 on hl-line) | `cursor` ¹ | `#e1420b` ² | `editorCursor`, `terminalCursor` |

¹ Overridden in `emacs/init.el`. leuven-dark ships comments `#767283`
(3.4:1) and the cursor `#e1420b`.
² Ghostty still has the shipped orange-red cursor. See
[Known gaps](#known-gaps).

## Syntax

These are leuven-dark's font-lock faces, unchanged except for comments. As in
Emacs, only *definitions* are coloured. Calls, references, numbers and
operators stay in the foreground colour.

| Face | Colour | Contrast | Used for |
|---|---|---|---|
| `font-lock-keyword-face` | `#ffff0b` | 14.8 | keywords, storage types |
| `font-lock-string-face` | `#ff7fff` | 7.4 | strings |
| `font-lock-doc-face` | `#fd95fa` | 8.2 | docstrings |
| `font-lock-comment-face` | `#9a969e` italic | 5.5 | comments (delimiters upright) |
| `font-lock-function-name-face` | `#ff996f` | 7.6 | function definitions |
| `font-lock-builtin-face` | `#ff9029` | 7.0 | builtins, `self` |
| `font-lock-type-face` | `#9fcb66` | 8.5 | types, classes |
| `font-lock-variable-name-face` | `#4ac964` | 7.5 | variable and parameter definitions |
| `font-lock-constant-face` | `#34c8d8` | 7.9 | constants, enum members |
| `font-lock-preprocessor-face` | `#837f87` | 4.1 | preprocessor, decorators |
| `link` | `#ff925a` underlined | 7.2 | links |

## Org

Set by `os-leuven-dark-org-faces` in `emacs/init.el`. The same colours apply
to Markdown and Quarto headings in VS Code.

### Headings

| Level | Emacs | Contrast | VS Code (text only) |
|---|---|---|---|
| 1 | white bold on a band `#1a6e75` (cyan `#06ffff` mixed 35% into the background), overline `#06ffff`, height 1.3 | 5.9 on the band | `#06ffff` bold |
| 2 | `#ffff0b` bold | 14.8 | same |
| 3 | `#06c8cf` bold | 7.7 | same |
| 4 | `#1a9cff` bold (shipped) | 5.5 | same |
| 5 | `#21da7a` bold (shipped) | 8.6 | same |
| 6 | `#ff883d` bold italic (shipped) | 6.7 | same |
| 7, 8 | `#d451d9`, `#077ffa` bold italic (shipped) | — | — |

### Task keywords

Each status is a filled chip: dark `#25202a` text on the colour, bold, with a
1px box in the background colour. The keywords come from
`org-todo-keywords` in `~/slimer/org-config.el`. The keyword-to-face mapping
(`org-todo-keyword-faces` and the `os-org-todo-*` faces) is in `emacs/init.el`.

| Keyword | Face | Fill | Text contrast |
|---|---|---|---|
| TODO | `org-todo` | yellow `#ffff0b` | 14.8 (5.5 on the level-1 band) |
| NEXT | `os-org-todo-next` | LightSkyBlue `#87cefa` | 9.3 |
| WAIT | `os-org-todo-wait` | orange `#ff9029` | 7.0 |
| HOLD | `os-org-todo-hold` | pink `#ff9bff` | 8.6 |
| DONE | `org-done` | SeaGreen3 `#43cd80` | 7.8 |
| CANCELLED | `os-org-todo-cancelled` | grey `#848088`, struck through | 4.1 |

Under any other theme the `os-org-todo-*` faces inherit `org-todo` or
`org-done`.

### Other Org faces

| Face | Colour | Contrast |
|---|---|---|
| `org-headline-done` (text of a DONE heading) | `#c4c0c8` italic | 8.9 (3.3 on the level-1 band) |
| `org-tag` | `#a9a5ad` italic on `#25202a` | 6.6 |

## Interface

### Mode-line / status bar

Set by `os-leuven-dark-mode-line-faces`. leuven-dark ships a tan bar with
dark text, on which doom-modeline's coloured icons were unreadable.

| Element | Colour |
|---|---|
| active bar | `#3c312a` background, `#cfccd2` text (7.9), 1px `#cfa161` box |
| inactive bar | `#25202a` background, `#848088` text, `#3e3944` box |
| buffer name, emphasis | `#ffffff` bold |
| hover, `warning`, LSP running | `#6f8cff` |

In VS Code: `statusBar.background` `#3c312a`, `statusBar.border` `#cfa161`.

### Minibuffer and completion

Set by `os-leuven-dark-minibuffer-faces`.

| Element | Emacs | VS Code |
|---|---|---|
| selected candidate | `vertico-current`: yellow `#ffff0b` bar, dark text (14.8) | `list.activeSelection*`, `quickInputList.focus*` |
| prompt | `minibuffer-prompt`: dark bold text on SeaGreen3 `#43cd80` (7.8) | — |
| matched text | `completions-common-part`, `orderless-match-face-0`: cyan `#06ffff` bold (12.7) | `list.highlightForeground` `#06ffff` |
| matched text on the selected row | the same colours, inverted into patches with dark text | `list.focusHighlightForeground` `#1a6e75` (5.5 on yellow) |
| orderless components 1–3 | pink `#ff9bff`, green `#78ff7c`, orange `#ff9029` | — |
| file-permission dashes | `marginalia-file-priv-no`: `#c4c0c8` | — |

In VS Code, menus and the suggest widget keep a burnt-orange `#752c0b`
selected row with white text. The yellow bar is only for the focused list.

## Status colours

| Meaning | Emacs | VS Code | Ghostty / terminal |
|---|---|---|---|
| error | `#06ffff` (shipped `error`) | `#ff8890` | red slots `#ff7138` / `#ff8890` |
| warning | `#6f8cff` (lifted from the shipped `#065aff`) | `#ff9029` | — |
| info | — | `#6f8cff` | — |
| success | `#ff01ff` (shipped `success`) | — | — |
| diff added / removed | shipped (purple / teal backgrounds) | green `#4ac964` / red-orange `#ff7138`, translucent | — |

Emacs and VS Code differ here on purpose. In VS Code, cyan already means
level-1 headings and matches, and `#6f8cff` means info.

## Terminal palette (ANSI)

These 16 colours are shared by Ghostty (`ghostty/themes/leuven-dark`) and VS
Code's integrated terminal. leuven-dark's own `ansi-color-names-vector` is
hue-rotated, so every slot instead takes the leuven-dark colour that actually
has that slot's hue.

| Slot | Normal | Bright |
|---|---|---|
| black (0/8) | `#3e3944` | `#848088` |
| red (1/9) | `#ff7138` | `#ff8890` |
| green (2/10) | `#4ac964` | `#78ff7c` |
| yellow (3/11) | `#b3af59` | `#ffff0b` |
| blue (4/12) | `#6f8cff` ³ | `#9db0ff` ³ |
| magenta (5/13) | `#e074e3` | `#ff9bff` |
| cyan (6/14) | `#34c8d8` | `#6bffff` |
| white (7/15) | `#cfccd2` | `#ffffff` |

³ Derived, not lifted. leuven-dark's only blues are dark backgrounds, so
these are lightened to at least 5:1.

## Known gaps

- **Ghostty cursor**: still the shipped `#e1420b`, not `#43cd80`.
- **VS Code shows no backgrounds on text.** A theme can only set a token's
  foreground and font style. So:
  - the level-1 band is cyan text;
  - task chips are the chip colour, bold and underlined. Links are the only
    other underlined text.
- **VS Code Org grammar** (`tootone.org-mode`):
  - It names only TODO and DONE, and only heading levels 1–4.
  - NEXT, WAIT, HOLD, CANCELLED and any acronym of three or more capitals in
    a heading share one scope, which is NEXT's sky blue `#87cefa`.
  - It has no scope for tags or for DONE headline text.
- **Cursor on the level-1 band** is 2.9:1, the one weak spot of SeaGreen3.

## Changing a colour

1. **Emacs.** Change the face in the matching `os-leuven-dark-*` function in
   `emacs/init.el`, and update the comment above it. There are two ways to
   apply a face:
   - Faces the shipped theme already styles go through
     `custom-theme-set-faces` plus `custom-theme-recalc-face`.
   - Faces it does not style must go through `os-custom-theme-apply-faces`,
     or the setting is silently dropped.

   Check the contrast against `#25202a`, and against `#2d2058` for anything
   that can sit on the cursor line.
2. **Ghostty.** If the colour is the background, foreground, cursor,
   selection or one of the 16 ANSI hues, edit `ghostty/themes/leuven-dark`.
   Check it with `ghostty +validate-config`, then reload with `<C-S-,>`.
3. **VS Code.** Edit `~/leuven-for-vscode/themes/leuven-dark-color-theme.json`
   (and its README's mapping tables), then run *Developer: Reload Window*.
4. **This file.** Update the tables above.
