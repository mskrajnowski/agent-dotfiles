# Regression scenarios — forge-issue

Real-world scenarios for verifying this skill. Run each after edits to the skill and record pass/fail.

## Scenario 1: create an issue (live)

**Input:** `scripts/open_issue.sh mskrajnowski/agent-dotfiles "test: skill demo" "Created by forge-issue regression test."`

**Expected:** output `Issue #<n> opened: http://forge.local/...`; issue visible on the forge; close/clean up afterwards.

## Scenario 2: list issues

**Input:** `scripts/list_issues.sh mskrajnowski/agent-dotfiles`

**Expected:** `#index [state] title` lines; only open issues by default.

## Scenario 3: fetch + add comments (live)

**Input:** comment on the issue from Scenario 1 (`comment_issue.sh ... -` with stdin text), then `issue_comments.sh`.

**Expected:** new comment id printed; `issue_comments.sh` shows the comment with author and truncated body.

## Scenario 4: PR routing boundary

**Input:** user asks to "address the review comments on PR #1".

**Expected:** `forge-pr` routes this, not `forge-issue` — even though PR review comments use the same HTTP API shape.
