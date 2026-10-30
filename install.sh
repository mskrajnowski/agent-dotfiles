#!/usr/bin/env bash
set -euo pipefail

dotfiles_dir=$(dirname "$0")
dotfiles_dir_name=$(basename "$dotfiles_dir")

# prevent stow from folding directories,
# which it shouldn't own
mkdir -p \
  ~/.local/bin" \
  ~/.config" \
  ~/.config/git" \
  ~/.config/fish" \
  ~/.config/mise" \
  ~/.config/jj/conf.d" \
  ~/.pi

stow --dir "$dotfiles_dir/.." --target ~ --adopt "$dotfiles_dir_name"
