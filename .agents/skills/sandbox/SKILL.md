---
name: sandbox
description: >-
  Documents the runtime environment — a Docker Sandboxes microVM, its trust boundary,
  network policy, credential handling, persistence, and what is or isn't available. Use
  whenever you need to know where you are running and what you can or cannot do — before
  making network requests to unfamiliar destinations, when connections or authentication
  to a service fail, before installing packages or tools, when judging what persists
  across restarts, when accessing host resources or services, or when reporting
  environment-related limitations to the user.
---

# Sandbox environment

This agent runs inside a [Docker Sandbox](https://docs.docker.com/ai/sandboxes/): a lightweight
microVM on the user's machine, isolated from the host by a hypervisor. It is not a plain
Docker container and not a cloud instance.

## What this environment is

- Full microVM: separate kernel, full privileges **inside** (sudo, package installation), but
  nothing on the host is reachable except what is explicitly shared (workspace, network via
  proxy, credentials via proxy).
- **Docker**: a private, isolated Docker Engine runs inside the sandbox. `docker build`,
  `docker pull`, compose etc. all work, but the image cache is per-sandbox and never shared
  with the host or other sandboxes.
- **Persistence**: installed packages, Docker images, agent state, and files outside a mounted
  workspace persist across stop/restart of the sandbox. They are lost only when the user
  removes the sandbox (`sbx rm`). Do not assume a rebuild is needed after a restart.
- Workspace files: the agent home is `/home/agent` (symlink to `/home/agents/<name>`), which
  lives on the host and is shared with the host workspace. Edits there are visible to the user
  in real time.

## Trust boundary — what crosses it

Only these cross the microVM boundary:

| Crossing | Direction | Notes |
| --- | --- | --- |
| Workspace files | both | live on the host; agent edits are immediately visible to the user |
| Outbound TCP traffic | sandbox → host | proxied through the host and filtered by network policy |
| Credentials | host → request | injected into HTTP headers by the host proxy; values never enter the VM |

Everything else on the host — filesystem, Docker daemon, local network, other sandboxes — is
unreachable. There is no path into the sandbox from the host either.

Details and the full isolation model: [references/ISOLATION.md](references/ISOLATION.md).

## Networking

- All outbound traffic (HTTP/HTTPS via a forward proxy, other TCP transparently) goes through a
  **filtering proxy on the host**. Network policy decides which destinations are allowed.
- **ICMP is blocked**; UDP is blocked unless the user enables the experimental UDP feature.
  IPv6 is blocked.
- This deployment denies the **host's local/private and loopback ranges**. The sandbox's own
  `localhost`/`127.0.0.1` is unaffected — services the agent starts inside the sandbox are
  reachable normally. The exception on the host side is a small set of **shared host
  services** reachable by hostname — the important one is `forge.local` (the Git forge).
  Always contact the forge by its hostname, never by IP.
- When a request fails with connection errors or timeouts, the likely cause is the network
  policy, not the destination. The agent cannot change policy itself — suggest actions to the
  user (see below).

## Credentials

API keys and tokens are **not stored in the sandbox**. The agent may see sentinel/placeholder
values in environment variables; the host proxy replaces them with the real value as the request
leaves the VM. Consequences:

- Never try to read, print, or extract credential values — the real ones are not here.
- If authentication to a service fails (401/403), the user likely hasn't configured that
  credential on the host. Suggest they configure it (e.g. `sbx` credential management on the
  host), not that the agent set an env var in the sandbox.

## Changing this environment

Tooling and configuration come from the agent-dotfiles repo:

- Cloned at `~/agent-dotfiles`, installed as a GNU stow package by `install.sh`.
- **Per-agent tools/config**: edit `~/agent-dotfiles` (skills in `.agents/skills/`, global
  instructions in `.agents/AGENTS.md`, tools in `.config/mise/`), then run
  `~/agent-dotfiles/install.sh` and `mise install`. Commit and push changes so future
  sandboxes get them. Changes to agent-dotfiles are welcome when they are universally useful
  to all agents.
- **Inside the sandbox**: the agent has full sudo access, so one-off system packages can be
  installed directly (`apt install ...`). For tools required by a project, use mise — see the
  `mise` skill for details.
- **Sandbox infrastructure** (base image, install steps run as root, workspace layout) is
  defined in the user's main dotfiles repo (the `agent`/`agent-kit` configuration) and is
  applied when a sandbox is created. If a change needs the base image or kit lifecycle to
  change, ask the user to update it there and recreate the sandbox — in-sandbox changes to the
  image do not persist into new sandboxes.

## When to ask the user

The agent cannot run `sbx` commands (they run on the host). Ask the user to:

- **Allow a destination**: `sbx policy ls` to inspect rules, then
  `sbx policy allow network <ip-range|hostname>`.
- **Configure a credential** for a service that returns auth errors.
- **Recreate the sandbox** after kit/base-image changes: `sbx rm <name>` then create it again.
- **Restart** the sandbox to recover from a wedged state without losing installed state.

## References

Loaded on demand — local summaries so no web fetch is needed for common questions:

- [references/ISOLATION.md](references/ISOLATION.md) — isolation layers, trust boundary details, credential injection
- [references/NETWORKING.md](references/NETWORKING.md) — proxy architecture, network policy, troubleshooting request failures
- [references/SETUP.md](references/SETUP.md) — how this sandbox is provisioned (kit, agent-dotfiles), lifecycle and persistence

Full documentation: https://docs.docker.com/ai/sandboxes/. Useful pages for deeper questions:

- Architecture (how the microVM, proxy, and storage work): https://docs.docker.com/ai/sandboxes/architecture/
- Security model and isolation: https://docs.docker.com/ai/sandboxes/security/
- Network rules/policy: https://docs.docker.com/ai/governance/local/network-rules/
- Credentials: https://docs.docker.com/ai/sandboxes/configuration/credentials/
- Environments (environment files): https://docs.docker.com/ai/sandboxes/configuration/environment-files/
- Kits: https://docs.docker.com/ai/sandboxes/customize/use-kits/
- Settings: https://docs.docker.com/ai/sandboxes/configuration/settings/
- CLI reference: https://docs.docker.com/reference/cli/sbx/
