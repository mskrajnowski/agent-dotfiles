# How this sandbox is provisioned

Summaries of the user's dotfiles (main repo: `sbx/`, `agent/`, `bin/install`) and
https://docs.docker.com/ai/sandboxes/customize/ (kits), plus the agent-dotfiles repo itself.

Deeper documentation for the entities below:

- Environments (environment files): https://docs.docker.com/ai/sandboxes/configuration/environment-files/
- Kits: https://docs.docker.com/ai/sandboxes/customize/use-kits/
- Settings: https://docs.docker.com/ai/sandboxes/configuration/settings/
- Lifecycle (run/stop/restart/remove): https://docs.docker.com/ai/sandboxes/architecture/

## Creation flow

1. The user defines the sandbox with an environment file (schemaVersion 1) in their main
   dotfiles repo: agent name, workspace path (`/home/agents/<name>`), and a **kit**
   (`agent-kit`).
2. A **kit** is a Dockerfile + manifest that packages the sandbox base image and install
   steps. Kit install commands run **as root inside the sandbox** when the sandbox is created.
3. The kit lifecycle then:
   - moves the home directory to `/home/agents/<name>` and symlinks `/home/agent` to it;
   - clones `agent-dotfiles` from the forge into `~/agent-dotfiles`;
   - runs `install.sh` (GNU stow links the dotfiles into `$HOME`);
   - runs `mise install` for pinned tools.
4. The user's host-side `sbx-setup` script (run once per machine, not per sandbox) applies
   settings (browser, clipboard, SSH agent forwarding off) and the network policy described
   in NETWORKING.md.

## Agent-dotfiles role

- Lives at `~/agent-dotfiles`; mirrored into `$HOME` via stow.
- Skills: `.agents/skills/` — global skills available in every session.
- Global instructions: `.agents/AGENTS.md`.
- Tools: `.config/mise/` — installed with `mise install`.
- After changing anything, run `~/agent-dotfiles/install.sh` and `mise install`, then commit
  and push so new sandboxes pick it up.

## Lifecycle and persistence

- Stopping the sandbox keeps the VM: packages, Docker images, and in-sandbox files survive a
  restart. Setup does not re-run.
- Removing the sandbox (`sbx rm`) deletes the VM and everything in it. The workspace directory
  under `/home/agents/<name>` is shared with the host.
- Kit changes (base image, root install steps) only apply to **newly created** sandboxes.
  Dotfile changes can be applied to a running sandbox by re-running `install.sh`.

## Where to change what

| Change | Where |
| --- | --- |
| Skills, instructions, dotfiles, mise tools | `~/agent-dotfiles` (this repo) |
| Base image packages, root-level install steps, workspace layout | main dotfiles repo, `agent-kit` (kit Dockerfile/manifest) — ask the user |
| Network policy, credentials, sandbox settings | host side, via `sbx` commands — ask the user |

Docs: https://docs.docker.com/ai/sandboxes/customize/
