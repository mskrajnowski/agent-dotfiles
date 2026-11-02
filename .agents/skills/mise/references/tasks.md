# mise tasks reference

## Formats

| Format | Use when | Location |
| --- | --- | --- |
| TOML task | command fits a line or two, or task mainly runs others | `[tasks.<name>]` in `mise.toml` |
| File task | script long enough to benefit from highlighting/linting | executable in `mise-tasks/` |

Start with TOML; move to a file task when the script grows. Both share the
same runner and most properties.

## TOML task

```toml
[tasks.test]
description = "Run test suite"
run = "pytest -q"

[tasks.check]
depends = ["lint", "test"]        # prerequisites; may run in parallel

[tasks.deploy]
depends = ["check"]
run = "./scripts/deploy.sh {{ arg(name='env', default='staging') }}"
```

## File task

`mise-tasks/hello` (make executable with `chmod +x`):

```sh
#!/usr/bin/env bash
#MISE description="Say hello"
echo "hello from a file task"
```

Define the name in the file OR in TOML, not both. Mise finds file tasks in
`mise-tasks/`, `.mise/tasks/`, or the directory set by the `tasks.dir` setting.

## Running

- `mise run <task> [args]` — runs with the project's tools and env; installs
  missing tools first unless `task.run_auto_install` is disabled. Shell
  activation not required.
- `mise tasks ls` — list tasks; `mise tasks info <name>` — definition source
  and details. Arguments validate via the task-arguments feature
  (https://mise.jdx.dev/tasks/task-arguments.html).

## Ordering: depends vs run steps

- `depends` entries run in parallel; list order does not sequence them.
- For strict sequencing use run steps (`run = ["a", "b"]` arrays) or
  `wait_for`; see https://mise.jdx.dev/tasks/architecture.html.
- `depends_post` runs after the task completes.

## Extras

- Caching: skip or restore work when inputs unchanged —
  https://mise.jdx.dev/tasks/caching.html
- Templates share tools/env/args across tasks —
  https://mise.jdx.dev/tasks/templates.html
- Monorepo: run tasks across several project roots —
  https://mise.jdx.dev/tasks/monorepo.html
- Full property reference — https://mise.jdx.dev/tasks/task-configuration.html
