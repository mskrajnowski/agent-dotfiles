---
name: forge
description: General knowledge about the user's forge — a local Forgejo instance. Use when the user mentions the forge, forge.local, PRs, issues, or asks what can be done with the forge. Routes to forge-pr or forge-issue for specific workflows.
---

# Forge

The user's forge is a local Forgejo instance at `http://forge.local` (version `17.0.1+gitea-1.22.0`; check `GET /api/v1/version` for the current value). It is the user's primary collaboration service with agents.

## Shared conventions (apply to every forge interaction)

- **API base:** `http://forge.local/api/v1`
- **Auth:** `curl --netrc` — `~/.netrc` holds credentials for both the API and git push/pull. Never print the credentials. The agent authenticates as the `setup` user — comments and reviews it posts appear "by setup", not by the repo owner (`mskrajnowski`).
- **Output discipline:** never dump raw JSON into context. Write responses to a file and summarize, filter with `jq`, or use the dedicated scripts in `forge-pr` and `forge-issue` (they do this for you).
- **Discover endpoints:** the full OpenAPI schema is at `http://forge.local/swagger.v1.json` — fetch it and search for the operation you need rather than guessing.
- **User actions:** the user merges PRs, closes/reopens PRs and issues, resolves review comments, and manages labels — the forge UI is theirs, and some of these (e.g. resolving review comments) have no API endpoint. Agents point to fixes by replying with short commit SHAs instead.
- **Sandbox:** test scripts and skills against `mskrajnowski/forge-skills-sandbox` — never against real repos. Create throwaway PRs/issues/branches there and leave the user to clean them up.

## Writing forge scripts

New scripts must follow the existing `forge-pr`/`forge-issue` patterns:

- Self-contained bash; `set -euo pipefail`; `mktemp` files with a `trap ... EXIT` cleanup.
- Build JSON payloads with `jq -n --arg ...`; never inline untrusted text into JSON strings.
- On success print a one-line confirmation (with ids, path:line, or short SHA). On failure print `ERROR: HTTP <code>` plus the response's `.message` to stderr and `exit 1`.
- Keep output for agent eyes: truncate comment bodies and timelines; never emit raw JSON.

## Forgejo 17 API notes

Hard-won quirks of this API version — trust these over assumptions when writing new scripts:

- **PRs are issues:** issue endpoints work with PR indexes — `GET/POST /issues/{index}/comments`, `GET /issues/{index}/timeline`, and issue state changes all apply to PRs.
- **Review comment fields differ from issue comments:** author is `.user.login` (`.poster.login` is used by issue comments), line is `.position`, and "resolved" is derived from `.resolver != null` — there is no `.resolved` boolean.
- **`in_reply_to` is silently ignored** by `POST /pulls/{index}/reviews/{id}/comments` — it creates a free-standing comment with an empty path and position. Threaded replies must post a comment on the same review at the same path + position (the UI groups those into one thread).
- **Swagger can overstate the API:** `GET /pulls/{index}/requested_reviewers` is documented but returns 404; the `POST` variant works and returns `201` with an empty array.
- **`GET /pulls/{index}` has no commit counts** (`commits: null`) — use `changed_files`, `additions`, `deletions` for change stats.
- **Timeline events** (`GET /issues/{index}/timeline?limit=50`) include `comment`, `close`, `pull_push`, `review`, `review_request`, and `change_title` events.

## Which skill to use

| Task | Skill |
|---|---|
| Open, list, review diffs, address review feedback, request reviews, update PRs | `forge-pr` |
| Create, list, comment on, or read issue timelines | `forge-issue` |

New workflows (boards, wikis, releases, etc.) get their own skill when the need arises — check the user's skills directory for anything newer than this list.
