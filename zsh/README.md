# Zsh Configuration

Personal zsh configuration with Oh-My-Zsh and Zinit plugin managers.

## Structure

Both files live in this subdirectory and are symlinked into `$HOME`.

`zsh/.zshenv` -> `~/.zshenv` contains **only** PATH. Zsh sources it on every
invocation (login, interactive, and plain `zsh -c` alike), which is what lets
Emacs' `exec-path-from-shell` pick up the full PATH from a ~2ms non-interactive
shell instead of a ~1s interactive login shell that first loads Oh-My-Zsh,
compinit, Zinit, nvm and fastfetch. Add new PATH entries there, not in
`.zshrc`; keep the file silent (no output, no tty assumptions).

`zsh/.zshrc` -> `~/.zshrc` holds everything interactive, organized into the
following sections:

| Section | Description |
|---------|-------------|
| PATH | Pointer to `.zshenv`, where PATH actually lives |
| Oh My Zsh | Theme and plugin setup |
| Zinit | Additional plugin manager with annexes |
| Aliases | Command shortcuts |
| Tool Initialization | Language toolchain setup |
| Startup | Shell startup commands |

## Plugin Managers

### Oh-My-Zsh

Using the `robbyrussell` theme with these plugins:
- `git` - Git aliases and functions
- `zsh-syntax-highlighting` - Command syntax coloring
- `zsh-autosuggestions` - Fish-like autosuggestions
- `zsh-history-substring-search` - Better history search
- `zsh-completions` - Additional completion definitions

### Zinit

Zinit is auto-installed if not present. Loaded annexes:
- `zinit-annex-as-monitor`
- `zinit-annex-bin-gem-node`
- `zinit-annex-patch-dl`
- `zinit-annex-rust`

## Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `vim` | `nvim` | Use Neovim |
| `vi` | `nvim` | Use Neovim |
| `tiny` | `nvim` | Use Neovim |
| `neomutt` | `TERM=xterm-direct neomutt` | NeoMutt with proper color support |
| `spyder` | (full path) | Spyder IDE |

## Tool Paths

Custom paths configured for:
- Julia (juliaup)
- Thunderbird
- Zotero
- Neovim

## Language Toolchains

- **NVM** - Node.js version manager
- **Conda** - Python/R environment manager (Miniconda)

## Installation

```bash
# Symlink to home directory
ln -sf $(pwd)/zsh/.zshenv ~/.zshenv
ln -sf $(pwd)/zsh/.zshrc ~/.zshrc

# Reload configuration
source ~/.zshrc
```

## Dependencies

- [Oh-My-Zsh](https://ohmyz.sh/)
- [Zinit](https://github.com/zdharma-continuum/zinit)
- [Fastfetch](https://github.com/fastfetch-cli/fastfetch) (for startup display)
