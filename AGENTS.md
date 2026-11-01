# Agent dotfiles repo

## About this repo

The main goal of this repo is to provide base configuration for the environment the agent is working in. That includes tools installed through mise and configuration as various dotfiles.

When the user asks to add something globally, include it here:

- Global skills go in `agent-dotfiles/.agents/skills/`
- Global instructions go in `agent-dotfiles/.agents/AGENTS.md`
- Global tools go in `agent-dotfiles/.config/mise/`

The repo mirrors `$HOME` and is installed as a single GNU stow package: run `./install.sh` from the repo root after changing files so everything (including skills) is linked into `$HOME` and discoverable. The stow ignore list lives in `.stow-local-ignore`.
