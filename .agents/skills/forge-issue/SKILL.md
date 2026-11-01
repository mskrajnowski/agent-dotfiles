---
name: forge-issue
description: Work with issues on the user's forge — create, list, update, fetch and add comments, get summaries with timelines. Use when the user asks to create an issue, look up issue comments, comment on an issue, or update an issue.
---

# Working with issues

Scripts live in this skill's directory; run them via relative path. All scripts use `curl --netrc` against `http://forge.local/api/v1` (see the `forge` skill for shared conventions). Each script prints only an agent-friendly summary — never raw JSON.

## Workflows

### Create an issue

```bash
scripts/open_issue.sh <owner>/<repo> <title> [body|-]
```

- `body` optional; reads stdin if `-` is passed. Returns the issue number and URL.

### List issues

```bash
scripts/list_issues.sh <owner>/<repo> [state]   # state: open|closed|all, default open
```

Prints `#index [state] title` per issue.

### Fetch issue comments

```bash
scripts/review_issue_comments.sh <owner>/<repo> <index>
```

Prints `id`, `author`, and body (truncated) per comment. Use to review discussion before acting.

### Comment on an issue

```bash
scripts/add_issue_comment.sh <owner>/<repo> <index> <text|->
```

Reads the comment from stdin if `-` is passed. Prints the new comment's id.

### Update an issue

```bash
scripts/update_issue.sh <owner>/<repo> <index> [--title <text>] [--body <text|->]
```

`--body -` reads the body from stdin. Title and body only — state changes (close/reopen) are the user's action.

### Get issue summary

```bash
scripts/get_issue_summary.sh <owner>/<repo> <index>
```

One-call summary: state, title, labels, the issue description, and a compact event timeline (comments, state changes, label events). Use to catch up on an issue without reading every comment; fetch full comments with `review_issue_comments.sh` when needed.

## Conventions

- Issue comments are written for human readers — plain markdown, no raw JSON.
- Read the issue discussion with `review_issue_comments.sh` before acting on it — don't repeat what was already said.
- For PR-related discussions, use `forge-pr` instead.
- Agents never edit or delete comments — post a new comment instead, so the discussion history stays traceable.
- Agents never close or reopen issues, or manage labels — those are the user's actions on the forge UI. Reference issues from PR descriptions (`Closes #N`) so they auto-close on merge (see `forge-pr`).
