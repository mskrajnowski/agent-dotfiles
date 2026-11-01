# Agent dotfiles repo

## About this repo

This is the user's agent dotfiles repo (`agent-dotfiles`). It mirrors `$HOME` and is installed as a single GNU stow package: run `./install.sh` from the repo root after changing files so everything (including skills in `.agents/skills/`) is linked into `$HOME` and discoverable. Ignore list for stow lives in `.stow-local-ignore`.

- The remote is the user's Forgejo instance at `forge.local` — open pull requests there after pushing.
- Forge API: `http://forge.local/api/v1` (OpenAPI schema at `http://forge.local/swagger.v1.json`). Use `curl --netrc` for API calls; `~/.netrc` holds the credentials for both API and git push/pull. Keep raw API output out of context — write responses to a file and summarize.
- Changes must be committed on a topic branch and reviewed via a PR before merging.
