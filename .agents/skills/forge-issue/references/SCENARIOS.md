# Regression scenarios — forge-issue

Real-world scenarios for verifying this skill. Run each after edits to the skill and record pass/fail.

## Scenario 1: create an issue (live)

**Input:** `scripts/open_issue.sh mskrajnowski/forge-skills-sandbox "test: skill demo" "Created by forge-issue regression test."`

**Expected:** output `Issue #<n> opened: http://forge.local/...`; issue visible on the forge.

## Scenario 2: list issues

**Input:** `scripts/list_issues.sh mskrajnowski/forge-skills-sandbox`

**Expected:** `#index [state] title` lines; only open issues by default.

## Scenario 3: fetch + add comments (live)

**Input:** comment on the issue from Scenario 1 (`add_issue_comment.sh ... -` with stdin text), then `review_issue_comments.sh`.

**Expected:** new comment id printed; `review_issue_comments.sh` shows the comment with author and truncated body.

## Scenario 3b: issue timeline (live)

**Input:** `scripts/review_issue_timeline.sh mskrajnowski/forge-skills-sandbox <issue>`

**Expected:** chronological event lines (comments, state changes), not just comments — no raw JSON.

## Scenario 4: PR routing boundary

**Input:** user asks to "address the review comments on PR #1".

**Expected:** `forge-pr` routes this, not `forge-issue` — even though PR review comments use the same HTTP API shape.
