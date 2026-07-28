#!/usr/bin/env bash

set -Eeuo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
backup_dir=${XDG_STATE_HOME:-$HOME/.local/state}/my-config-files/backups/$(date +%Y%m%d-%H%M%S)
backed_up=false

link_config() {
  local source=$1 target=$2 current

  mkdir -p -- "$(dirname -- "$target")"
  if [[ -L $target ]]; then
    current=$(readlink -f -- "$target" 2>/dev/null || true)
    if [[ $current == "$source" ]]; then
      printf 'Already linked: %s\n' "$target"
      return
    fi
  fi

  if [[ -e $target || -L $target ]]; then
    mkdir -p -- "$backup_dir"
    mv -- "$target" "$backup_dir/$(basename -- "$target")"
    backed_up=true
    printf 'Backed up: %s\n' "$target"
  fi

  ln -s -- "$source" "$target"
  printf 'Linked: %s -> %s\n' "$target" "$source"
}

link_config "$repo_dir/nvim" "$HOME/.config/nvim"
link_config "$repo_dir/neomutt" "$HOME/.config/neomutt"
link_config "$repo_dir/neovide" "$HOME/.config/neovide"
link_config "$repo_dir/fastfetch" "$HOME/.config/fastfetch"
link_config "$repo_dir/zsh/.zshrc" "$HOME/.zshrc"
link_config "$repo_dir/emacs/init.el" "$HOME/.emacs.d/init.el"

if [[ $backed_up == true ]]; then
  printf '\nPrevious configuration saved under %s\n' "$backup_dir"
fi
