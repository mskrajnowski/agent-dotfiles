# Regression scenarios — forge-issue

Real-world scenarios for verifying this skill. Run each after edits to the skill and record pass/fail.

Live scenarios run against a throwaway test repo you create first (see the `forge` skill's testing convention: create → test → delete). Substitute your test repo for `<test-repo>` in the commands below.

## Scenario 1: create an issue (live)

**Input:** `scripts/open_issue.sh <test-repo> "test: skill demo" "Created by forge-issue regression test."`

**Expected:** output `Issue #<n> opened: http://forge.local/...`; issue visible on the forge.

## Scenario 2: list issues

**Input:** `scripts/list_issues.sh <test-repo>`

**Expected:** `#index [state] title` lines; only open issues by default.

## Scenario 3: fetch + add comments (live)

**Input:** comment on the issue from Scenario 1 (`add_issue_comment.sh ... -` with stdin text), then `review_issue_comments.sh`.

**Expected:** new comment id printed; `review_issue_comments.sh` shows the comment with author and truncated body.

## Scenario 3a: update an issue (live)

**Input:** `scripts/update_issue.sh <test-repo> <issue> --title "..." --body -` (body from stdin)

**Expected:** confirmation line; `get_issue_summary.sh` shows the new title/body. Only title and body — no state change.

## Scenario 3b: issue summary (live)

**Input:** `scripts/get_issue_summary.sh <test-repo> <issue>`

**Expected:** state, title, labels, description, and chronological event lines (comments, state changes) — no raw JSON.

## Scenario 4: PR routing boundary

**Input:** user asks to "address the review comments on PR #1".

**Expected:** `forge-pr` routes this, not `forge-issue` — even though PR review comments use the same HTTP API shape.
