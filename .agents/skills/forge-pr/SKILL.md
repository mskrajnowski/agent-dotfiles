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

### Add a general PR comment

```bash
scripts/add_pr_comment.sh <owner>/<repo> <index> <text|->
```

Use to summarize what was addressed (mention the commit), explain decisions, or give status updates.

### Add an inline review comment

```bash
scripts/add_pr_review_comment.sh <owner>/<repo> <index> <path> <line> <text|->
```

Marks a specific place in the diff — use to flag spots needing the user's feedback (architecture decisions, unclear instructions, alternatives worth discussing).

### Reply to a review comment

```bash
scripts/reply_pr_review_comment.sh <owner>/<repo> <index> <review-id> <comment-id> <text|->
```

Posts a review comment in the same review at the same path:line, which the forge UI groups into the original thread (the API has no explicit `in_reply_to`; thread membership is by review + path + position). After addressing feedback, reply with a short commit SHA — the forge renders bare SHAs as clickable commit links. The comment ids come from `review_pr_comments.sh` output (`COMMENT <review-id>-<id>`).

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
