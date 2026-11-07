#!/usr/bin/env bash
set -euo pipefail

dotfiles_dir=$(dirname "$0")

# prevent stow from folding directories,
# which it shouldn't own
mkdir -p \
  ~/.agents/skills \
  ~/.config \
  ~/.config/fish \
  ~/.config/git \
  ~/.config/jj/conf.d \
  ~/.config/mise \
  ~/.local/bin \
  ~/.pi/agent/agents \
  ~/.claude/skills

stow --dir "$dotfiles_dir" --target ~ --adopt .
