# =============================================================================
#                                   PATH
# =============================================================================

export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

# Tool-specific paths
path=(
    '/home/simon/.juliaup/bin'
    '/home/simon/opt/thunderbird/bin'
    '/home/simon/opt/zotero/bin'
    '/home/simon/opt/nvim-linux-x86_64/bin'
    $path
)
export PATH

# =============================================================================
#                               OH MY ZSH
# =============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search)

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
alias vi=nvim
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

# Conda
__conda_setup="$('/home/simon/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/simon/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/simon/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/simon/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# =============================================================================
#                                STARTUP
# =============================================================================

fastfetch --logo-type file --logo /home/simon/ascii/machine.txt
