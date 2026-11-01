---
name: forge-pr
description: Work with pull requests on the user's forge — open, list, fetch review comments, resolve review feedback. Use when the user asks to open a PR, review PR comments, or address review feedback. Agents do not merge PRs; merging is the user's action.
---

# Working with pull requests

Scripts live in this skill's directory; run them with the skill dir as cwd or via relative path. All scripts use `curl --netrc` against `http://forge.local/api/v1` (see the `forge` skill for shared conventions). Each script prints only an agent-friendly summary — never raw JSON.

## Workflows

### Open a PR

```bash
scripts/open_pr.sh <owner>/<repo> <head> <base> <title> [body]
```

- `body` optional; reads stdin if `-` is passed. Returns the PR number and URL.
- Branch must exist on the remote first: `git push -u origin <head>`.

### List PRs

```bash
scripts/list_prs.sh <owner>/<repo> [state]   # state: open|closed|all, default open
```

Prints `#index [state] title (head→base)` per PR.

### Fetch review comments

```bash
scripts/review_pr_comments.sh <owner>/<repo> <index>
```

Prints each review's state and every comment (`id`, `path`, `line`, `author`, `body`), plus which comments are already resolved. This is the core loop for addressing feedback: read comments → fix code → commit → force-push (`--force-with-lease`) → resolve the comment when done.

### Merging

Agents never merge PRs. After the PR is opened and review feedback is addressed, hand the decision to the user. If asked to merge, explain that merging is the user's action.

### Update a PR

Use the API directly for title/body changes:
`PATCH /repos/{owner}/{repo}/pulls/{index}` with `{"title":..., "body":...}` (body file + jq, no raw dump).

## Conventions

- PR titles use Conventional Commits (per the repo's commit rules).
- After amending and force-pushing, tell the user which review comments were addressed and which remain open.

## Harness notes

### Pi

- Pair this skill with `writing-skills` when a review leads to edits; the commit rules live in the repo's `AGENTS.md`.
- Review-comment fetching is read-only — safe to run repeatedly mid-session.
