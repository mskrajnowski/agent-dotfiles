# mise documentation table of contents

Curated map of https://mise.jdx.dev for further research. Generated from the
official sitemap (2026-10); every CLI subcommand also has a page at
`/cli/<command>.html` (nested subcommands at `/cli/<group>/<sub>.html`).

## Start here

- Getting started — /getting-started.html
- Walkthrough for an existing project — /walkthrough.html
- Installing mise — /installing-mise.html
- Registry of 1,000+ tools — /registry.html
- FAQ — /faq.html · Troubleshooting — /troubleshooting.html · Error codes — /errors.html

## Configuration

- Config files & locations (`mise.toml` precedence, where writes land) — /configuration.html
- Full `mise.toml` reference — /configuration/reference.html
- `[settings]` reference — /configuration/settings.html
- `[vars]` — /configuration/vars.html
- Config environments (`MISE_ENV`, `mise.<env>.toml`) — /configuration/environments.html
- `MISE_*` environment variables — /configuration/environment-variables.html
- Project diagnostics — /configuration/project-diagnostics.html
- Tera templates (`{{config_root}}`, `{{ tools.* }}`, filters) — /templates.html
- Hooks (pre/post project enter/leave) — /hooks.html

## Dev tools

- Dev tools guide (everyday commands) — /dev-tools/
- Version requests & idiomatic version files (`.nvmrc`, `.python-version`) — /dev-tools/versions.html
- Lockfiles (`mise.lock`) — /dev-tools/mise-lock.html · lock file format — /dev-tools/mise-lock-reference.html
- Shims vs activation vs exec — /dev-tools/shims.html
- Aliases — /dev-tools/aliases.html
- Tool stubs — /dev-tools/tool-stubs.html
- Upgrade/prune, self-updating tools, auto_update — /dev-tools/self-updating-tools.html
- Install layout / system installs — /dev-tools/install-layout.html · /dev-tools/system-installs.html
- GitHub API rate limits/tokens — /dev-tools/github-tokens.html
- Language guides: /lang/node.html · python · go · rust · ruby · java · bun · deno · dotnet · elixir · erlang · swift · zig
- asdf migration — /dev-tools/comparison-to-asdf.html

### Backends

Overview — /dev-tools/backends/ — then: aqua, cargo, npm, pypi, go, gem, github, gitlab, http, ubi, vfox, asdf, conda, dotnet, s3, forgejo, packslip, spinel, spm (each `/dev-tools/backends/<name>.html`)

## Environments

- Environment variables (`[env]`, directives, precedence) — /environments/
- Secrets & redaction — /environments/secrets/ — SOPS: /environments/secrets/sops.html · age: /environments/secrets/age.html · fnox (secret manager): /environments/secrets/fnox.html
- direnv integration — /direnv.html

## Tasks

- Tasks guide — /tasks/
- TOML tasks — /tasks/toml-tasks.html · file tasks — /tasks/file-tasks.html
- Running tasks, args, task env — /tasks/running-tasks.html
- Dependencies & ordering (`depends`, `wait_for`, run steps) — /tasks/architecture.html
- Task arguments (CLI interface, validation) — /tasks/task-arguments.html
- Full task property reference — /tasks/task-configuration.html
- Discovery & precedence — /tasks/task-discovery.html
- Templates (shared settings) — /tasks/templates.html
- Caching — /tasks/caching.html · remote cache — /tasks/remote-cache.html
- Monorepo — /tasks/monorepo.html · workspace graph — /tasks/workspace-graph.html
- OpenTelemetry — /tasks/opentelemetry.html

## Shells, IDEs, CI

- Shell setup & activation (bash, zsh, fish, nushell, powershell…) — /shell-setup.html
- Shell aliases — /shell-aliases.html
- IDE/editor integration — /ide-integration.html
- CI / GitHub Action — /continuous-integration.html

## Machine setup

- Bootstrap (packages, dotfiles, repos, services) — /bootstrap.html
- Bootstrap sub-guides: /bootstrap/packages/, repos, dotfiles, services, remote (SSH), secrets, shell, macos-defaults, systemd/launchd
- Dotfiles — /dotfiles.html (reference: /dotfiles/reference.html)
- Daemons (background dev services) — /daemons.html

## Security & trust

- Configuration trust, safe mode, `minimum_release_age` — /security.html
- Sandboxing — /sandboxing.html
- Paranoid mode — /paranoid.html

## Reference / advanced

- Directories mise uses — /directories.html
- Cache behavior — /cache-behavior.html
- Plugins (tool/env/package) — /plugins.html; development: /tool-plugin-development.html · /env-plugin-development.html · /backend-plugin-development.html
- Tips and tricks — /tips-and-tricks.html
- Cookbook (node, python, ruby, docker, bazel, neovim, terraform…) — /mise-cookbook/
- Glossary — /glossary.html
- CLI reference index — /cli/ (every subcommand, incl. `mise doctor`, `mise reshim`, `mise settings`)

## Quick lookup — "I need to…"

- …find which config file wins → /configuration.html
- …pin exact versions for reproducibility → /dev-tools/mise-lock.html
- …load a `.env` or keep values out of plaintext → /environments/ and /environments/secrets/
- …make `node` work in an editor → /dev-tools/shims.html or /ide-integration.html
- …run tools in CI → /continuous-integration.html
- …set up a new machine → /bootstrap.html
- …diagnose a broken setup → `mise doctor` (no page needed) then /troubleshooting.html
