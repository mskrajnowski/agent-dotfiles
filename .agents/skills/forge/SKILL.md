---
name: forge
description: General knowledge about the user's forge — a local Forgejo instance. Use when the user mentions the forge, forge.local, PRs, issues, or asks what can be done with the forge. Routes to forge-pr or forge-issue for specific workflows.
---

# Forge

The user's forge is a local Forgejo instance at `http://forge.local`. It is the user's primary collaboration service with agents.

## Shared conventions (apply to every forge interaction)

- **API base:** `http://forge.local/api/v1`
- **Auth:** `curl --netrc` — `~/.netrc` holds credentials for both the API and git push/pull. Never print the credentials.
- **Agent identity:** `GET /api/v1/user` returns the account the agent authenticates as — it may differ per agent and from the user's own account. Check it when it matters who authored a comment or review.
- **Output discipline:** never dump raw JSON into context. Write responses to a file and summarize, filter with `jq`, or use the dedicated scripts in `forge-pr` and `forge-issue` (they do this for you).
- **User actions:** the user merges PRs, closes/reopens PRs and issues, resolves review comments, and manages labels — the forge UI is theirs, and some of these (e.g. resolving review comments) have no API endpoint. Agents point to fixes by replying with short commit SHAs instead.
- **Reply quotes:** when replying outside a thread (PR-level/issue comments, or free-standing review comments), quote the original in forgejo's own format — `@<author> wrote in <permalink>:`, blank line, blockquoted original, blank line, reply text. The header is NOT part of the blockquote, and the blank lines are required or the reply renders as part of the quote. Threaded replies to diff comments get the original shown above in the UI, so don't quote those.
- **Testing:** never test scripts or skills against real repos. Create a throwaway repo (e.g. `<agent>-forge-skills-sandbox` via `POST /repos`), run the tests against it, then delete it (`DELETE /repos/{owner}/{repo}`) when done.
- **Going beyond the scripts:** the forge-pr/forge-issue scripts cover the common workflows. For direct API calls, read `references/API.md` first — it documents API quirks, field-name differences, and silently-ignored parameters. The full OpenAPI schema is at `http://forge.local/swagger.v1.json`.

## Writing forge scripts

New scripts must follow the existing `forge-pr`/`forge-issue` patterns:

- Python 3.12+ uv scripts (PEP 723): `#!/usr/bin/env -S uv run --script` shebang and an inline `dependencies = ["requests"]` header, so uv provisions dependencies on first run.
- Use `requests` directly — there is deliberately no shared client module. Each script defines its own `FORGE_URL`/`BASE`/`TIMEOUT` constants, creates a `requests.Session()` (auth is picked up from `~/.netrc` automatically — never set an explicit `auth=` or Authorization header, that would override netrc), and passes `timeout=TIMEOUT` on every call.
- Each caller parses its own response: `.json()` when the endpoint returns JSON, `.text` for plain-text endpoints (e.g. the `.diff` URL). Never dump raw JSON to stdout.
- Each script carries its own tiny `fail(resp, context)` helper that prints `ERROR: HTTP <code>[ (<context>)]` plus the API's `.message` to stderr and exits 1 — keep the error contract identical across scripts.
- CLI and presentation helpers (stdin `-` handling, indentation, timeline rendering) live directly in the scripts that use them — don't re-extract them into a shared module.
- Parse the CLI with `argparse` (types for indexes, `choices` for states); don't hand-roll positional/flag parsing.
- On success print a one-line confirmation (with ids, path:line, or short SHA). On failure print `ERROR: HTTP <code>` plus the response's `.message` to stderr and `exit 1` (the `fail()` helper does this).
- Keep output for agent eyes: truncate comment bodies and timelines; never emit raw JSON.
- Format and lint with `ruff` (config in `.agents/skills/ruff.toml`): `uvx ruff format` and `uvx ruff check --fix` over the changed script dirs.

## Which skill to use

| Task | Skill |
|---|---|
| Open, list, review diffs, address review feedback, request reviews, update PRs | `forge-pr` |
| Create, list, comment on, or read issue timelines | `forge-issue` |

New workflows (boards, wikis, releases, etc.) get their own skill when the need arises — check the user's skills directory for anything newer than this list.
