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
  ~/.pi/agent \
  ~/.claude \
  ~/.claude/skills

stow --dir "$dotfiles_dir" --target ~ --adopt .

# claude writes synced claude.ai skills into ~/.claude/skills, so link each
# skill in individually to keep that directory out of the repo
for skill in "$dotfiles_dir"/.agents/skills/*/; do
  name=$(basename "$skill")
  ln -sfn "../../.agents/skills/$name" ~/.claude/skills/"$name"
done
