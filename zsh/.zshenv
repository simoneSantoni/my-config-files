# =============================================================================
#                                   PATH
# =============================================================================
#
# This file is sourced by *every* zsh invocation — login, interactive, and
# plain `zsh -c` scripts alike — which is exactly why PATH lives here and not
# in .zshrc. Emacs' exec-path-from-shell asks a shell for its PATH at startup;
# with PATH defined here it can use a bare non-interactive `zsh -c` (~20ms)
# instead of an interactive login shell that has to drag in oh-my-zsh, compinit,
# zinit and nvm first (~1s, which trips exec-path-from-shell's "execution took
# a lot of time" warning). See `exec-path-from-shell-arguments' in ~/.emacs.d/init.el.
#
# Keep this file silent and cheap: no output, nothing that assumes a tty, and
# no tool initialisation — all of that belongs in .zshrc.

# -U keeps `path' deduplicated, so re-entering zsh from an already-configured
# environment doesn't grow PATH with every nesting level.
typeset -U path PATH

path=(
    $HOME/.juliaup/bin
    $HOME/.julia/bin
    $HOME/.cargo/bin
    $HOME/opt/thunderbird/bin
    $HOME/opt/zotero/bin
    $HOME/opt/nvim-linux-x86_64/bin
    $HOME/bin
    $HOME/.local/bin
    /usr/local/bin
    /usr/bin
    /bin
    /usr/sbin
    /sbin
    $path
)
export PATH
