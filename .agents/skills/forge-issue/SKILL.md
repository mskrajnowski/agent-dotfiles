---
name: forge-issue
description: Work with issues on the user's forge — create, list, fetch and add comments, manage labels. Use when the user asks to create an issue, look up issue comments, comment on an issue, or manage issue labels.
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

## Conventions

- Issue comments are written for human readers — plain markdown, no raw JSON.
- Labels and other attributes: use the API directly (`GET/POST/PUT /repos/{owner}/{repo}/issues/{index}/labels`), summarizing responses like everything else.

## Harness notes

### Pi

- Use `issue_comments.sh` before acting on an issue — context discipline says read the discussion first.
- For PR-related discussions, use `forge-pr` instead.
