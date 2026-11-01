# Regression scenarios — forge-pr

Real-world scenarios for verifying this skill. Run each after edits to the skill and record pass/fail.

## Scenario 1: open a PR (live)

**Input:** `scripts/open_pr.sh mskrajnowski/agent-dotfiles test/skill-demo main "test: skill demo"`

**Expected:**
- Output is exactly `PR #<n> opened: http://forge.local/...` — no raw JSON.
- PR is visible on the forge. Close it afterwards.

## Scenario 2: fetch review comments (live, PR #1)

**Input:** `scripts/pr_reviews.sh mskrajnowski/agent-dotfiles 1`

**Expected:**
- Review states printed, comments flattened with `resolved=` status, `path:line`, author, and truncated bodies. No raw JSON dump.
- Bad index (e.g. 9999) → clean `ERROR` message, non-zero exit.

## Scenario 3: list PRs

**Input:** `scripts/list_prs.sh mskrajnowski/agent-dotfiles` and `... all`

**Expected:** `#index [state] title (head->base)` lines; open by default, all includes merged/closed.

## Scenario 4: merge a non-mergeable PR (negative)

**Input:** merge a PR with unresolved conflicts or against an already-merged branch.

**Expected:** script reports the PR state and exits non-zero with a clear reason; does not force anything.

## Scenario 5: near-miss routing

**Input:** user asks to "create an issue about the flaky test".

**Expected:** `forge-issue` routes this, not `forge-pr`.
