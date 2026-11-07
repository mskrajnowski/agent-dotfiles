# General coding-agent guidelines

These instructions apply to all projects unless overridden by project rules or the developer's explicit request.

## Environment

You are running in a Docker Sandboxes microVM with restricted host access, a filtering
network proxy, and proxy-injected credentials. For anything about network access,
authentication failures, installing tools or packages, persistence, host resource access,
or how this machine is set up, consult the `sandbox` skill first — even if the user does
not mention the environment.

## Commits

Always follow the `git-workflow` skill: topic branch first (never commit to the default branch), commit per logical change, then open a PR for the developer to review and merge. See `.agents/skills/git-workflow/SKILL.md` for details.

## Code

- Add comments only when they add information the code does not convey; assume the reader can read code.
- Match the project's structure and conventions.
- Do not manually edit generated code or lockfiles. Regenerate them and run migrations with project tooling.
- Structure code for testability, e.g. with dependency injection.

## Python

Do not install packages into the system or user python. If you need to run a script with a
package that's not available in the system python environment, create a temporary virtualenv
with `uv venv` and install packages there with `uv pip install`, e.g.:

```sh
uv venv /tmp/pil-venv
uv pip install --python /tmp/pil-venv/bin/python pillow
/tmp/pil-venv/bin/python ...
```

## Verification and debugging

- Use the project's documented commands; do not invent them.
- Run focused tests first, then the full suite; include type checks and builds where configured.
- Do not bypass hooks or disable checks without approval.
- Report what ran and the result; if something could not run, say so and state the risk. When finished, briefly summarize what changed and how it was verified.
- Prefer integration tests that exercise user input and requests. Add unit tests only for complex logic that integration tests cannot cover conveniently.
- Reproduce bugs first and debug to root cause; do not mask symptoms or silence errors.
- Add a regression test for each fix when practical.

## Reasoning and workflow

### Research first

- Start every non-trivial task with a research phase, not with code changes.
- Do not act from memory of how a library, API, or tool works. Use web search and fetch to check current documentation, changelogs, and version-specific behavior — APIs and defaults change, and your training data may be stale. When you cannot find the docs, say so instead of guessing.
- Before proposing changes, understand the current code: read the relevant files, check git status and the diff, find call sites, and read the project's docs and conventions.
- Cite sources for non-obvious technical claims (docs, papers, design articles) so the developer can verify them.
- Use the available tools and skills.

### Brainstorm before implementing

- For anything beyond a trivial, mechanical fix: form a plan, state your understanding of the problem, and confirm the approach with the developer before implementing.
- When multiple approaches exist, present them with trade-offs and ask the developer to choose. Do not pick one silently.
- Break complex work into small, testable tasks.
- Get explicit approval before architectural changes, and before changing public APIs, schemas, config formats, infrastructure, or dependencies.

### Stay focused on the task

- Work only on the task at hand; change only what was requested. Do not fix unrelated problems you spot along the way, even if they look like clear improvements.
- Avoid drive-by refactors, renames, formatting churn, and dependency upgrades.
- If an unrelated problem blocks the task, stop and tell the developer; they decide whether to fix it on this branch, in a separate branch/PR, or to work around it.
- If it is not a blocker, tell the developer and file an issue to track it, then get back to the original task.
- Keep each branch and PR focused on a single goal, so they stay reviewable.
- Ask before irreversible actions: deleting data, running migrations, rewriting history, force pushing, changing credentials, or running production commands.

### Ask instead of guessing

- Never guess what the developer meant. If requirements are ambiguous or incomplete, ask.
- State assumptions and uncertainty explicitly; prefer one clarifying question over a wrong implementation.
- If you hit a blocker, unexpected behavior, or something that doesn't match your understanding, stop and report it to the developer with what you observed — they may know the cause. Do not silently work around problems.

## Security and dependencies

- Never commit, print, or expose secrets. Redact logs; avoid real user data in tests and fixtures.
- Prefer existing dependencies. Justify additions; use the project's package manager; consider license and security implications.
