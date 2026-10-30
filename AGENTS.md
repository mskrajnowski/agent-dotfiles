# General coding-agent guidelines

These instructions apply to all projects unless overridden by project rules or the developer's explicit request.

## Commits

- Create a topic branch first so the developer can review and pull it.
- Make atomic, single-responsibility commits. Split unrelated changes into separate commits.
- Keep diffs small and reviewable; stage only files relevant to the commit. Do not mix formatting changes with behavior changes.
- Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
- Keep commit messages brief and specific. Add detail only when it helps; no essays.

## Code

- Add comments only when they add information the code does not convey; assume the reader can read code.
- Match the project's structure and conventions.
- Do not manually edit generated code or lockfiles. Regenerate them and run migrations with project tooling.
- Structure code for testability, e.g. with dependency injection.

## Verification and debugging

- Use the project's documented commands; do not invent them.
- Run focused tests first, then the full suite; include type checks and builds where configured.
- Do not bypass hooks or disable checks without approval.
- Report what ran and the result. If something could not run, say so and state the risk.
- Prefer integration tests that exercise user input and requests. Add unit tests only for complex logic that integration tests cannot cover conveniently.
- Reproduce bugs first and debug to root cause; do not mask symptoms or silence errors.
- Add a regression test for each fix when practical.

## Reasoning and workflow

- Do not guess the developer's intent. Ask when requirements are ambiguous and state assumptions or uncertainty explicitly.
- Verify current information with web search or fetch instead of relying on memory.
- Before editing, read project docs and conventions and check git status and the diff. Understand the code, its call sites, and its libraries' documentation; plan before implementing.
- Break complex work into small, testable tasks.
- Get approval before architectural changes. Propose alternatives and ask explicitly before changing public APIs, schemas, config formats, infrastructure, or dependencies.
- Cite sources so the developer can verify and learn, including for non-obvious technical claims, e.g. docs, papers, or design-pattern articles.
- Use the available tools and skills.
- When finished, briefly summarize what changed and how it was verified.

## Scope and safety

- Change only what was requested. Avoid drive-by refactors, renames, formatting churn, and dependency upgrades.
- Report anything you noticed but deliberately did not change.
- Ask before irreversible actions: deleting data, running migrations, rewriting history, force pushing, changing credentials, or running production commands.

## Security and dependencies

- Never commit, print, or expose secrets. Redact logs; avoid real user data in tests and fixtures.
- Prefer existing dependencies. Justify additions; use the project's package manager; consider license and security implications.
