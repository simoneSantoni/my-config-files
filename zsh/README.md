# Zsh Configuration

Personal zsh configuration with Oh-My-Zsh and Zinit plugin managers.

## Structure

The `.zshrc` is organized into the following sections:

| Section | Description |
|---------|-------------|
| PATH | System and tool-specific path configuration |
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
ln -sf $(pwd)/.zshrc ~/.zshrc

# Reload configuration
source ~/.zshrc
```

## Dependencies

- [Oh-My-Zsh](https://ohmyz.sh/)
- [Zinit](https://github.com/zdharma-continuum/zinit)
- [Fastfetch](https://github.com/fastfetch-cli/fastfetch) (for startup display)
