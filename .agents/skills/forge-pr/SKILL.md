---
name: forge-pr
description: Work with pull requests on the user's forge — open, list, review diffs and comments, reply to feedback, request reviews. Use when the user asks to open a PR, review PR comments, or address review feedback. Agents do not merge PRs or resolve review comments; merging and resolving are the user's actions.
---

# Working with pull requests

Scripts live in this skill's directory; run them with the skill dir as cwd or via relative path. They are [uv inline-dependency scripts](https://docs.astral.sh/uv/guides/scripts/) — run them directly (`./scripts/foo.py`) or via `uv run --script scripts/foo.py`; **never** with a bare `python`/`python3` invocation, which skips uv's dependency resolution and fails with `ModuleNotFoundError`. All scripts use `curl --netrc` against `http://forge.local/api/v1` (see the `forge` skill for shared conventions). Each script prints only an agent-friendly summary — never raw JSON.

**The `-` convention:** a trailing `[body|-]`/`<text|->` argument is *only* the last, optional text argument — `-` there reads that text from stdin. All other positional arguments must be given literally on the command line; `-` is never a placeholder for them.
## Workflows

### Open a PR

```bash
scripts/open_pr.py <owner>/<repo> <head> <base> <title> [body]
```

- `body` optional; reads stdin if `-` is passed. Returns the PR number and URL.
- Branch must exist on the remote first: `git push -u origin <head>`.

```bash
# title, head, base are literal arguments; only the body comes from stdin via '-'
scripts/open_pr.py owner/repo feat/my-change main "feat(scope): summary" - <<'HEREDOC'
PR description on stdin
HEREDOC
```

### List PRs

```bash
scripts/list_prs.py <owner>/<repo> [state]   # state: open|closed|all, default open
```

Prints `#index [state] title (head→base)` per PR.

### Fetch review comments

```bash
scripts/review_pr_comments.py <owner>/<repo> <index>
```

Prints each review's state and every comment (`id`, `path`, `line`, `author`, `body`), plus which comments are already resolved. This is the core loop for addressing feedback: read comments → fix code → commit → force-push (`--force-with-lease`) → reply to each addressed comment with the short commit SHA.

### Add a general PR comment

```bash
scripts/add_pr_comment.py <owner>/<repo> <index> <text|->
```

Use to summarize what was addressed (mention the commit), explain decisions, or give status updates.

```bash
scripts/add_pr_comment.py owner/repo 7 - <<'HEREDOC'
Comment text on stdin
HEREDOC
```

### Add an inline review comment

```bash
scripts/add_pr_review_comment.py <owner>/<repo> <index> <path> <line> <text|->
```

Marks a specific place in the diff — use to flag spots needing the user's feedback (architecture decisions, unclear instructions, alternatives worth discussing).

```bash
scripts/add_pr_review_comment.py owner/repo 7 src/api.py 42 - <<'HEREDOC'
Comment text on stdin
HEREDOC
```

### Reply to a review comment

```bash
scripts/reply_pr_review_comment.py <owner>/<repo> <index> <review-id> <comment-id> <text|->
```

```bash
scripts/reply_pr_review_comment.py owner/repo 7 105 203 - <<'HEREDOC'
Reply text on stdin
HEREDOC
```

The comment ids come from `review_pr_comments.py` output (`COMMENT <review-id>-<id>`). Behavior depends on the comment type:

- **Threaded review comment** (has a file anchor): the reply is posted on the same review with the same path and positions — forgejo groups it into the original thread (the API has no explicit `in_reply_to`; thread membership is by review + path + position). The reply body is plain text — do not quote the original; the thread already shows it above the reply.
- **Free-standing comment** (no file anchor): the reply is posted as a general PR comment quoting the original (author, id, body), since free-standing comments get no thread UI.

The script warns when the branch has moved since the comment was made — a reply posted against a changed diff can land as a separate thread. **Reply before pushing**: fix → commit locally → reply to each addressed comment with the short commit SHA (the forge renders bare SHAs as clickable links) → push.

### Review the PR diff

```bash
scripts/review_pr_diff.py <owner>/<repo> <index> [diff|stats]
```

- `diff` (default) — full unified diff of the PR. Write large diffs to a file and summarize.
- `stats` — one line per changed file with add/delete counts.

Use before opening a PR to double-check its contents, and when reviewing what a PR actually changes.

### Get PR summary

```bash
scripts/get_pr_summary.py <owner>/<repo> <index>
```

One-call summary: state, mergeability, head→base, change stats, unresolved review comment count, requested reviewers, review states, the PR description, and a compact event timeline. Use to check a PR's situation without dumping JSON or reading the whole conversation.

### Request review

```bash
scripts/request_pr_review.py <owner>/<repo> <index> <username>...
```

Requests (or re-requests) review. Re-request after force-pushing fixes.

### Update a PR

```bash
scripts/update_pr.py <owner>/<repo> <index> [--title <text>] [--body <text|-|->]
```

Title and body only — state changes (close/reopen) are the user's action.

`--body -` reads the body from stdin.

```bash
scripts/update_pr.py owner/repo 7 --body - <<'HEREDOC'
New body on stdin
HEREDOC
```

### Merging

Agents never merge PRs. After the PR is opened and review feedback is addressed, hand the decision to the user. If asked to merge, explain that merging is the user's action.

## Conventions

- PR titles use Conventional Commits (per the repo's commit rules).
- Reference the issues a PR resolves in its description (`Closes #N`, `Fixes #N`) — forgejo auto-closes them when the user merges.
- When addressing review feedback: fix → commit locally → reply to each addressed comment with the short commit SHA → push. Reply before pushing — pushing changes the diff and can split replies into separate threads. Then re-request review.
- Agents never edit or delete comments — post a new comment instead, so the discussion history stays traceable.
- Agents never merge PRs, close/reopen PRs, resolve review comments, or manage labels — those are the user's actions on the forge UI. Reply with the commit that addressed the feedback instead; the user resolves it.
- Review-comment fetching is read-only — safe to run repeatedly mid-session.
