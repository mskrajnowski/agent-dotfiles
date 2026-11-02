# mise environments reference

Source: https://mise.jdx.dev/environments/

## Where `[env]` applies

| How a command runs | Receives `[env]` |
| --- | --- |
| `mise exec -- <command>` | yes |
| `mise run <task>` | yes, plus the task's own `env` |
| activated shell | yes, recomputed per directory change |
| shim | yes, for the program the shim runs |
| `mise en` | yes, in a static subshell |

Values can be strings, integers (`true` becomes `"true"`), or tables
(`default`, `required`, `tools = true`, `redact = true`). Set a variable to
`false` to unset one inherited from the shell or a lower-precedence config.

## CLI

- `mise set FOO=bar` writes to `[env]` in the nearest config with a
  directory; `mise set FOO` prints it; `mise set` lists all with source files.
  `-E staging` writes `mise.staging.toml`, `-g` the global config,
  `--prompt`/`--stdin` keeps values out of shell history.
- `mise env` prints the resolved environment including `PATH` entries and
  tool-set variables; `--json` / `--dotenv` formats.
- `mise unset FOO` removes it.

## defaults and required

```toml
[env]
NODE_ENV = { default = "development" }          # only set when unset/empty
DATABASE_URL = { required = "Set DATABASE_URL to your PostgreSQL connection string" }
```

`required` is validated, never assigned — something else (env,
`mise.local.toml`, parent config, global config) must set it. Missing
required vars abort `mise exec`/`mise run`/`mise env` with the help text;
activated shells only warn. Cannot combine `required` with `value`/`default`.
Mark values `redact = true` to mask them in task output (CI masking).

## Precedence

Higher wins: `mise.<env>.local.toml` > `mise.local.toml` > `mise.<env>.toml`
(`MISE_ENV`) > `mise.toml` > parent-directory config > global config. Files
evaluate low→high, entries top-to-bottom, so a value can reference anything
defined before it.

## Templates and expansion

Values are Tera templates (`{{config_root}}`, `{{env.NAME}}`,
`{{ tools.node.version }}`) with shell-style expansion applied after
(`$VAR`, `${VAR}`, `${VAR:-default}`). A value can only reference variables
defined above it, in lower-precedence files, or in the starting environment.
`env_shell_expand = false` disables expansion.

`[env]` resolves before tools, so values can configure tool installs
(e.g. `CFLAGS`); add `tools = true` to an entry that needs tool values
(`{{ tools.node.version }}`, `_.path` entries under tool paths).

## Env directives (`env._.*`)

```toml
[env]
_.file = [".env", { path = ".secrets.yaml", redact = true }]
_.path = ["bin", { path = "~/bin", position = "append" }]
_.source = { path = "scripts/env.sh", redact = true }
_.python.venv = { path = ".venv", create = true }
```

- `_.file`: extension picks the parser — `.json`/`.yaml`/`.toml` parsed
  structurally (values literal), anything else as dotenv (shell-like
  quoting, values may reference earlier entries). Globs load every match;
  missing paths are skipped silently. `expand = true` lets any format
  reference earlier values. `find_up = true` searches config root and
  parents (monorepo root `.env`).
- `_.path`: prepended ahead of tool paths unless `position = "append"`.
  Never write `PATH` directly in `[env]` — it is ignored.
- `_.source`: sourced with bash each time the env is computed; keep it
  fast. Only *prepended* `PATH` entries are kept. Never runs in safe mode.
- `_.python.venv`: creates/activates a virtualenv, always resolves last.
- Plugin directives: `_.<plugin-name> = { ... }` for installed environment
  plugins.

Directives take `path`, `tools`, and (where supported) `redact` /
`position` / `expand` / `find_up` options.

## Escape hatches

- `mise --no-env` / `MISE_NO_ENV=1` / `no_env` setting: skip all config env.
- Safe mode `MISE_SAFE=1`: ignore project env and directives, never run
  `_.source` (untrusted repos).

## Deprecated syntax (removed 2026.12+)

- `env.mise.*` → `env._.*`
- `value`/`values` in directive tables → `path`
- top-level `env_file`/`dotenv` → `_.file`; top-level `env_path` → `_.path`

## Related

- Secrets & redaction: https://mise.jdx.dev/environments/secrets/
- Config environments (`MISE_ENV`): https://mise.jdx.dev/configuration/environments.html
- Hooks on enter/leave: https://mise.jdx.dev/hooks.html
