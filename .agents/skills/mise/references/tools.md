# mise tools reference

## How mise selects a tool

1. Config files are read from the current directory upward, plus the global
   config (`~/.config/mise/config.toml`); closer files override farther ones.
2. The registry maps short names (`node`, `python`) to backends (aqua,
   cargo, npm, pypi, github releases, vfox, ...). See
   https://mise.jdx.dev/registry.html for the 1,000+ tools.
3. The version request (`24`, `latest`, `3.14`) is resolved; an already
   installed matching version is reused before fetching newer. A lockfile
   (`mise.lock`) fixes the exact result.
4. Selected tools are put on `PATH` for the command, task, or shell.

`mise exec` and `mise run` install missing tools automatically before running.

## Version requests and pinning

- `node = "24"` — newest matching release; upgrades within the request via
  `mise upgrade node` (config unchanged).
- `mise use --pin node@24` — writes the exact resolved version instead.
- `mise upgrade --bump node` — installs the newest release and rewrites the
  request with the same precision (`"24"` → `"26"`).
- `mise lock` / `mise.lock` — commit this file to make builds reproducible;
  `mise upgrade` updates it.

## Aliases and backends

- Short names come from the registry; a version request can name a backend
  explicitly, e.g. ` aqua: prefix`, `cargo:ripgrep`, `npm:prettier`, or a
  custom `asdf:`-style git plugin.
- `[tool_alias]` in config defines local aliases (this machine uses e.g.
  `skills-ref = "pipx:skills-ref"`).

## Global config patterns

Personal defaults live in `~/.config/mise/config.toml`:

```toml
[tools]
node = { version = "24", auto_update = "6h" }
```

- `auto_update = true | "6h"` keeps a global tool current; updates stay
  within the request, never touch project configs, and are skipped offline,
  in CI, or for exact pins. Global-only feature.
- `minimum_release_age = "3d"` holds back releases younger than that
  (supply-chain protection; default is 24h for backends that report dates).

## Cleanup

- `mise outdated` / `mise outdated --global` — tools with newer releases
  (`--bump` compares against newest overall).
- `mise unuse <tool>` removes the request; installed versions nobody needs
  are pruned.
- `mise uninstall node@22` / `--all` deletes installed versions explicitly.
- `mise prune` removes all versions no tracked config still needs.

## Version files from other tools

- `.tool-versions` is read as-is.
- `.nvmrc`, `.python-version`, `.ruby-version`, etc. only take effect when
  idiomatic version files are enabled for those tools:
  https://mise.jdx.dev/dev-tools/versions.html#idiomatic-version-files

Coming from asdf: https://mise.jdx.dev/dev-tools/comparison-to-asdf.html
