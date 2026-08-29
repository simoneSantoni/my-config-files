# =============================================================================
#                                   PATH
# =============================================================================
#
# PATH now lives in ~/.zshenv, which zsh sources on *every* invocation — see
# the comment there. Keeping it out of .zshrc is what lets Emacs'
# exec-path-from-shell read PATH from a cheap non-interactive `zsh -c' instead
# of an interactive login shell that first loads oh-my-zsh, zinit and nvm.

# =============================================================================
#                               OH MY ZSH
# =============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(git zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting)

# zsh-completions (must be added to fpath before compinit)
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

autoload -U compinit && compinit
source $ZSH/oh-my-zsh.sh

# =============================================================================
#                                 ZINIT
# =============================================================================

if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})...%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Zinit annexes
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# =============================================================================
#                                ALIASES
# =============================================================================

alias vim=nvim
alias tiny=nvim
alias neomutt='TERM=xterm-direct neomutt'
alias spyder=/home/simon/.local/spyder-6/envs/spyder-runtime/bin/spyder
alias uninstall-spyder=/home/simon/.local/spyder-6/uninstall-spyder.sh

# =============================================================================
#                           TOOL INITIALIZATION
# =============================================================================

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Conda (lazy-loaded — first call to conda/activate/deactivate runs the hook)
export CONDA_ROOT="/home/simon/miniconda3"
conda()      { unset -f conda activate deactivate; eval "$("$CONDA_ROOT/bin/conda" shell.zsh hook)"; conda "$@"; }
activate()   { conda activate   "$@"; }
deactivate() { conda deactivate "$@"; }

# Anthropic API key (for codecompanion.nvim)
# Store with: pass insert anthropic/api-key
if command -v pass >/dev/null 2>&1 && pass ls anthropic/api-key >/dev/null 2>&1; then
  export ANTHROPIC_API_KEY="$(pass show anthropic/api-key)"
fi

# =============================================================================
#                                STARTUP
# =============================================================================

# Use a host-specific fastfetch logo when one exists (e.g. stellaris16.txt)
if [[ -f ~/.config/fastfetch/$HOST.txt ]]; then
  fastfetch --logo ~/.config/fastfetch/$HOST.txt
else
  fastfetch
fi
