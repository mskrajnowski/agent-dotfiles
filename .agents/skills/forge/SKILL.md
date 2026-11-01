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
- **Testing:** never test scripts or skills against real repos. Create a throwaway repo (e.g. `<agent>-forge-skills-sandbox` via `POST /repos`), run the tests against it, then delete it (`DELETE /repos/{owner}/{repo}`) when done.
- **Going beyond the scripts:** the forge-pr/forge-issue scripts cover the common workflows. For direct API calls or new scripts, read `references/API.md` first — it documents API quirks, field-name differences, silently-ignored parameters, and script conventions. The full OpenAPI schema is at `http://forge.local/swagger.v1.json`.

## Which skill to use

| Task | Skill |
|---|---|
| Open, list, review diffs, address review feedback, request reviews, update PRs | `forge-pr` |
| Create, list, comment on, or read issue timelines | `forge-issue` |

New workflows (boards, wikis, releases, etc.) get their own skill when the need arises — check the user's skills directory for anything newer than this list.
