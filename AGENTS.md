# Repository Guidelines

## Project Structure & Module Organization

This repository stores Linux desktop configuration by application. Keep changes in the matching top-level directory:

- `nvim/`: LazyVim configuration; core settings are in `lua/config/`, plugin specs in `lua/plugins/`, and custom Tree-sitter queries in `queries/`.
- `emacs/`: the single-file Emacs configuration (`init.el`) plus its native-module helper.
- `neomutt/`: mail settings, MIME handlers, signature, and color schemes.
- `neovide/`, `fastfetch/`, and `zsh/`: focused configuration for each tool.
- `hhkb/`: keyboard profile snapshots and decoded layouts; treat `profile-backup.toml` as the known-good restore point.
- `scripts/`: host setup automation.

Update the nearest component README when behavior, dependencies, or installation steps change.

## Build, Test, and Development Commands

There is no repository-wide build or test suite. Validate the component you changed:

```bash
stylua --check nvim/               # check Lua formatting
stylua nvim/                       # format Neovim Lua files
zsh -n zsh/.zshrc                  # parse-check the shell configuration
bash -n scripts/setup-tuxedo-fedora.sh
emacs --batch -Q -l emacs/init.el  # smoke-test Emacs loading
```

For interactive checks, start the relevant application with the repository file symlinked as described in `README.md`. Avoid running hardware write commands for HHKB profiles unless the target device and profile index have been confirmed.

## Coding Style & Naming Conventions

Follow the style already used by each tool. Lua uses two spaces and a 120-column limit from `nvim/stylua.toml`; use `snake_case` for local functions and descriptive kebab-case plugin filenames such as `telescope-zotero.lua`. Shell scripts should retain their existing interpreter and use quoted expansions. Keep TOML, JSONC, and NeoMutt files grouped into readable topical sections. Do not commit generated caches, credentials, machine secrets, or editor state.

## Testing Guidelines

Run syntax and formatting checks before committing, then perform a focused startup smoke test. For UI, theme, keymap, or mail-rendering changes, document the manual scenario tested. This repository has no coverage target or test-file naming convention.

## Commit & Pull Request Guidelines

Recent history favors short, lowercase, imperative summaries (for example, `added zulip, mu4e, org-roam`). Prefer a more specific component-scoped subject, such as `nvim: add Quarto preview support`. Keep commits focused. Pull requests should explain the affected application, motivation, validation performed, and any new dependencies. Include screenshots for visible theme/UI changes and call out machine-specific paths, credentials, or hardware risks.
