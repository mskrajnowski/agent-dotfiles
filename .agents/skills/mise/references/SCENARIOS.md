# Test scenarios for the mise skill

Recorded use cases to verify against when editing this skill.

## 1. Routing

- Input: "how do I install node 22 for this project with mise?"
  Expected: skill activates; answer uses `mise use node@22` + `mise exec`.
- Input: "what is the capital of France?"
  Expected: skill does not activate.
- Input: "add a task to run tests via mise"
  Expected: skill activates; tasks section or references/tasks.md used.

## 2. Command accuracy

- Every command in SKILL.md's everyday table runs without error against the
  installed mise (use harmless ones: `mise ls --current`, `mise ls-remote node`,
  `mise tasks ls`, `mise config ls`).

## 3. Pitfall correctness

- Running `mise use --global fd@latest` then `mise exec -- fd --version`
  works in a non-activated shell (validates pitfall #1 guidance).
- `mise which fd` prints a path under `~/.local/share/mise/installs`.

## 4. Environment variables

- In a temp project with `[env] FOO = "bar"`, `mise exec -- sh -c 'echo $FOO'`
  prints `bar`; a plain shell without activation does not.
- `mise set FOO=bar` writes `[env]` to the project's `mise.toml`;
  `mise unset FOO` removes it.
- A `required` variable that is unset makes `mise exec` fail with the help
  text, while an activated shell only warns.

## 5. Reference loading

- All key commands and information live in SKILL.md; it links only to the
  mise docs (https://mise.jdx.dev) for further research — no separate
  reference summaries to keep in sync.
