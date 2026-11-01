---
name: forge-issue
description: Work with issues on the user's forge — create, list, update, fetch and add comments, get summaries with timelines. Use when the user asks to create an issue, look up issue comments, comment on an issue, or update an issue.
---

# Working with issues

Scripts live in this skill's directory; run them via relative path. They are [uv inline-dependency scripts](https://docs.astral.sh/uv/guides/scripts/) — run them directly (`./scripts/foo.py`) or via `uv run --script scripts/foo.py`; **never** with a bare `python`/`python3` invocation, which skips uv's dependency resolution and fails with `ModuleNotFoundError`. All scripts use `curl --netrc` against `http://forge.local/api/v1` (see the `forge` skill for shared conventions). Each script prints only an agent-friendly summary — never raw JSON.

**The `-` convention:** a trailing `[body|-]`/`<text|->` argument is *only* the last, optional text argument — `-` there reads that text from stdin. All other positional arguments must be given literally on the command line; `-` is never a placeholder for them.
## Workflows

### Create an issue

```bash
scripts/open_issue.py <owner>/<repo> <title> [body|-]
```

- `body` optional; reads stdin if `-` is passed. Returns the issue number and URL.

```bash
# title is a literal argument; only the body comes from stdin via '-'
scripts/open_issue.py owner/repo "Title here" - <<'HEREDOC'
Body text on stdin
HEREDOC
```

### List issues

```bash
scripts/list_issues.py <owner>/<repo> [state]   # state: open|closed|all, default open
```

Prints `#index [state] title` per issue.

### Fetch issue comments

```bash
scripts/review_issue_comments.py <owner>/<repo> <index>
```

Prints `id`, `author`, and body (truncated) per comment. Use to review discussion before acting.

### Comment on an issue

```bash
scripts/add_issue_comment.py <owner>/<repo> <index> <text|->
```

Reads the comment from stdin if `-` is passed. Prints the new comment's id.

```bash
scripts/add_issue_comment.py owner/repo 12 - <<'HEREDOC'
Comment text on stdin
HEREDOC
```

### Update an issue

```bash
scripts/update_issue.py <owner>/<repo> <index> [--title <text>] [--body <text|->]
```

`--body -` reads the body from stdin. Title and body only — state changes (close/reopen) are the user's action.

```bash
scripts/update_issue.py owner/repo 12 --body - <<'HEREDOC'
New body on stdin
HEREDOC
```

### Get issue summary

```bash
scripts/get_issue_summary.py <owner>/<repo> <index>
```

One-call summary: state, title, labels, the issue description, and a compact event timeline (comments, state changes, label events). Use to catch up on an issue without reading every comment; fetch full comments with `review_issue_comments.py` when needed.

## Conventions

- Issue comments are written for human readers — plain markdown, no raw JSON.
- Read the issue discussion with `review_issue_comments.py` before acting on it — don't repeat what was already said.
- For PR-related discussions, use `forge-pr` instead.
- Agents never edit or delete comments — post a new comment instead, so the discussion history stays traceable.
- Agents never close or reopen issues, or manage labels — those are the user's actions on the forge UI. Reference issues from PR descriptions (`Closes #N`) so they auto-close on merge (see `forge-pr`).
