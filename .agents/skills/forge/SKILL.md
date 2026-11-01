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

## Which skill to use

| Task | Skill |
|---|---|
| Create, review, merge, or update pull requests | `forge-pr` |
| Create, comment on, or manage issues | `forge-issue` |

New workflows (boards, wikis, releases, etc.) get their own skill when the need arises — check the user's skills directory for anything newer than this list.
