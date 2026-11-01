---
name: forge
description: General knowledge about the user's forge — a local Forgejo instance. Use when the user mentions the forge, forge.local, PRs, issues, or asks what can be done with the forge. Routes to forge-pr or forge-issue for specific workflows.
---

# Forge

The user's forge is a local Forgejo instance at `http://forge.local` (Forgejo/Gitea flavor, version via `GET /api/v1/version`). It is the user's primary collaboration service with agents.

## Shared conventions (apply to every forge interaction)

- **API base:** `http://forge.local/api/v1`
- **Auth:** `curl --netrc` — `~/.netrc` holds credentials for both the API and git push/pull. Never print the credentials.
- **Output discipline:** never dump raw JSON into context. Write responses to a file and summarize, filter with `jq`, or use the dedicated scripts in `forge-pr` and `forge-issue` (they do this for you).
- **Discover endpoints:** the full OpenAPI schema is at `http://forge.local/swagger.v1.json` — fetch it and search for the operation you need rather than guessing.
- **User actions:** the user merges PRs, closes/reopens PRs and issues, resolves review comments, and manages labels — the forge UI is theirs, and some of these (e.g. resolving review comments) have no API endpoint. Agents point to fixes by replying with short commit SHAs instead.

## Which skill to use

| Task | Skill |
|---|---|
| Open, list, review diffs, address review feedback, request reviews, update PRs | `forge-pr` |
| Create, list, comment on, or read issue timelines | `forge-issue` |

New workflows (boards, wikis, releases, etc.) get their own skill when the need arises — check the user's skills directory for anything newer than this list.
