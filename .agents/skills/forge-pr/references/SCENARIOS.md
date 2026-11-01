# Regression scenarios — forge-pr

Real-world scenarios for verifying this skill. Run each after edits to the skill and record pass/fail.

Live scenarios run against a throwaway test repo — see the `forge` skill's testing convention (create it, test, delete it). The repo name in the examples below (`mskrajnowski/forge-skills-sandbox`) is a leftover from earlier testing sessions; use the current test repo instead.

## Scenario 1: open a PR (live)

**Input:** `scripts/open_pr.sh mskrajnowski/forge-skills-sandbox test/skill-demo main "test: skill demo"`

**Expected:**
- Output is exactly `PR #<n> opened: http://forge.local/...` — no raw JSON.
- PR is visible on the forge. Close it afterwards.

## Scenario 2: fetch review comments (live, sandbox PR with reviews)

**Input:** `scripts/review_pr_comments.sh mskrajnowski/forge-skills-sandbox 1`

**Expected:**
- Review states printed, comments flattened with `resolved=` status, `path:line`, author, and truncated bodies. No raw JSON dump.
- Bad index (e.g. 9999) → clean `ERROR` message, non-zero exit.

## Scenario 3: list PRs

**Input:** `scripts/list_prs.sh mskrajnowski/forge-skills-sandbox` and `... all`

**Expected:** `#index [state] title (head->base)` lines; open by default, all includes merged/closed.

## Scenario 3b: add comment + reply to review comment (live)

**Input:**
- `scripts/add_pr_comment.sh mskrajnowski/forge-skills-sandbox <pr> "Addressed in commit abc1234"`
- `scripts/reply_pr_review_comment.sh mskrajnowski/forge-skills-sandbox <pr> <review-id> <comment-id> "Fixed by …"`
- `scripts/add_pr_review_comment.sh mskrajnowski/forge-skills-sandbox <pr> <path> <line> "Question: …"`

**Expected:**
- Each script prints a confirmation id (comment id / review id) — no raw JSON, no `null` fields.
- Reply to a **threaded** comment: body is plain text — no quote, no "In reply to" header; `review_pr_comments.sh` shows it at the same path:line as the original (same thread).
- Reply to a **free-standing** comment (no path): posted as a PR comment quoting the original, with a blank line separating the quote from the reply.
- Replying after the branch has moved prints a `WARN` about possible thread splitting.

## Scenario 3c: diff, status, review request, update (live)

**Input:**
- `scripts/review_pr_diff.sh mskrajnowski/forge-skills-sandbox <pr> stats` (then `diff`)
- `scripts/get_pr_summary.sh mskrajnowski/forge-skills-sandbox <pr>`
- `scripts/request_pr_review.sh mskrajnowski/forge-skills-sandbox <pr> mskrajnowski`
- `echo "Closes #1" | scripts/update_pr.sh mskrajnowski/forge-skills-sandbox <pr> --body -`

**Expected:**
- Diff/stats show the changed files; the summary is a one-call overview (state, mergeable, stats, unresolved comment count, description, timeline).
- Review request and update each confirm in one line — no raw JSON, no 404.

## Scenario 4: merge refusal

**Input:** user asks to merge a PR.

**Expected:** agent explains that merging is the user's action and does not call any merge API.

## Scenario 5: near-miss routing

**Input:** user asks to "create an issue about the flaky test".

**Expected:** `forge-issue` routes this, not `forge-pr`.
