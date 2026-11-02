---
name: mise
description: Use mise (https://mise.jdx.dev/) to install dev tools, manage per-project tool versions, set environment variables, and define/run tasks in mise.toml. Use when the user mentions mise, mise.toml, .tool-versions, installing tools like node/python/ruby/go, per-project tool versions, or mise tasks. Covers `mise use/install/exec/run/upgrade`, config file locations, and shell activation.
---

# mise

mise installs a project's tools, sets its environment variables, and runs its
tasks from `mise.toml`. Check the installed version with `mise --version`; the
CLI help (`mise <command> --help`) is authoritative and the docs at
https://mise.jdx.dev cover the rest.

## Core model

1. Config files (`mise.toml`, `~/.config/mise/config.toml`) declare `[tools]`,
   `[env]`, and `[tasks]`. mise reads them from the current directory, its
   parents, and the global config; the closest file wins. `mise config ls`
   shows which files apply.
2. A `[tools]` entry like `node = "24"` is a *request*, not a pin — mise
   installs a matching version and reuses it. Pin with exact versions or
   `mise lock`; see [tools reference](references/tools.md).
3. Tools land on `PATH` via shell activation, shims, or by prefixing commands
   with `mise exec --`. Scripts and CI should use `mise exec` / `mise run`,
   never assume activation.

## Everyday commands

| Goal | Command |
| --- | --- |
| Add/set a project's tool version | `mise use node@24` |
| Set a personal default | `mise use --global node@24` |
| Install tools the config declares | `mise install` |
| Run one command with the project's tools | `mise exec -- node --version` |
| Try a version without saving it | `mise exec node@24 -- node --version` |
| Show current tools | `mise ls --current` |
| List installable versions | `mise ls-remote node` |
| Upgrade within the request | `mise upgrade node` |
| Upgrade to newest and rewrite request | `mise upgrade --bump node` |
| Remove from config | `mise unuse node` |
| Delete installed version | `mise uninstall node@22` |

## Environment variables

Set project env vars under `[env]` in `mise.toml`. They apply to `mise exec`,
`mise run`, shims, and activated shells — never to the config itself
(`MISE_*` variables must be set in the real environment).

```toml
[env]
NODE_ENV = "production"
DATABASE_URL = { required = "Set to your PostgreSQL connection string" }
_.file = ".env"                                   # optional; missing files are skipped
_.path = ["bin", "{{config_root}}/node_modules/.bin"]
_.python.venv = { path = ".venv", create = true }
```

- `mise set FOO=bar` / `mise unset FOO` edit `[env]` from the CLI;
  `mise env` prints the resolved environment (`--dotenv`/`--json` formats).
- Directives live in the `_` table: `_.file` (dotenv/json/yaml/toml),
  `_.path` (PATH entries, `position = "append"` to go behind tool paths),
  `_.source` (run a bash script and take what it exports — keep it fast,
  it runs on every env computation). See
  [environments reference](references/environments.md).
- Values are Tera templates plus shell-style expansion:
  `LD_LIBRARY_PATH = "{{config_root}}/lib:${LD_LIBRARY_PATH:-}"`.
- `NODE_ENV = false` unsets a variable; `{ default = "..." }` only sets it
  when not already set.
- Precedence: project config beats parent dirs beats global;
  `mise.local.toml` and `mise.<MISE_ENV>.toml` layer on top.
- `mise --no-env` (or `MISE_NO_ENV=1`) skips all config env; safe mode
  (`MISE_SAFE=1`) ignores project env and never runs `_.source`.
- Secrets: `redact = true` masks values in output; SOPS files and secret
  managers via https://mise.jdx.dev/environments/secrets/.

## Tasks

Define short tasks as TOML in `mise.toml`; move longer scripts to executable
files in `mise-tasks/` (shebang + `#MISE description="..."` comment).

```toml
[tasks.test]
description = "Run tests"
run = "pytest -q"

[tasks.check]
depends = ["lint", "test"]   # prerequisites run in parallel
```

`mise run test` (installs missing tools first, unless disabled). `mise tasks ls`
lists tasks; `mise tasks info <name>` shows where one is defined. Task args,
dependencies, and caching: see [tasks reference](references/tasks.md).

## Common pitfalls

- **`command not found` right after `mise use`**: in an activated shell, the
  environment refreshes at the next prompt. In the same non-interactive shell,
  use `mise exec -- <cmd>`.
- **Wrong version running**: `mise which <cmd>` shows the binary mise would
  pick; a parent directory's config may be selecting it. Check `mise config ls`.
- **Writing config to the wrong file**: `mise use` edits the first loaded
  config that declares the tool, or creates `mise.toml` in the project. Use
  `--global` / `--path` to target a file explicitly.
- **Other version files**: `.tool-versions` is read natively; `.nvmrc`,
  `.python-version`, etc. need `idiomatic_version_file_enable_tools` enabled.
- **CI/containers**: `mise install` then `mise exec`/`mise run`; cache
  `~/.local/share/mise` between runs. There's an official GitHub Action.

## mise.toml quick example

```toml
[tools]
node = "24"
python = "3.14"

[env]
NODE_ENV = "development"

[tasks.dev]
run = "npm run dev"
```

## Deeper topics

Full docs: https://mise.jdx.dev — start here when this skill doesn't
cover something:

- [Config files & precedence](https://mise.jdx.dev/configuration.html), full [`mise.toml` reference](https://mise.jdx.dev/configuration/reference.html), [`[settings]`](https://mise.jdx.dev/configuration/settings.html)
- [Tool versions & idiomatic version files](https://mise.jdx.dev/dev-tools/versions.html), [lockfiles](https://mise.jdx.dev/dev-tools/mise-lock.html)
- [Shims vs activation vs exec](https://mise.jdx.dev/dev-tools/shims.html)
- [Tool backends](https://mise.jdx.dev/dev-tools/backends/), [tool registry](https://mise.jdx.dev/registry.html)
- Language guides: [node](https://mise.jdx.dev/lang/node.html), [python](https://mise.jdx.dev/lang/python.html), [go](https://mise.jdx.dev/lang/go.html), …
- [Secrets & redaction](https://mise.jdx.dev/environments/secrets/)
- Task [arguments](https://mise.jdx.dev/tasks/task-arguments.html), [dependencies & ordering](https://mise.jdx.dev/tasks/architecture.html), [caching](https://mise.jdx.dev/tasks/caching.html), [monorepo](https://mise.jdx.dev/tasks/monorepo.html)
- [Shell setup](https://mise.jdx.dev/shell-setup.html) (bash, zsh, fish, …), [IDE integration](https://mise.jdx.dev/ide-integration.html), [CI](https://mise.jdx.dev/continuous-integration.html)
- [Bootstrap](https://mise.jdx.dev/bootstrap.html) (machine setup, dotfiles, services)
- [Security, trust, safe mode](https://mise.jdx.dev/security.html), [hooks](https://mise.jdx.dev/hooks.html), [templates](https://mise.jdx.dev/templates.html)
- [Troubleshooting](https://mise.jdx.dev/troubleshooting.html), [CLI subcommand index](https://mise.jdx.dev/cli/)

- Tool versions, pinning, lockfiles, backends: [references/tools.md](references/tools.md)
- Environment variables, directives, precedence, secrets: [references/environments.md](references/environments.md)
- Tasks (args, dependencies, file tasks, caching): [references/tasks.md](references/tasks.md)
