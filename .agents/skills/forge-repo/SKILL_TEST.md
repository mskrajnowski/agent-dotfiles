# Regression scenarios — forge-repo

Real-world scenarios for verifying this skill. Run each after edits to the skill and record pass/fail.

Read-only listing scenarios run against the live forge; they create nothing and change nothing. If a scenario needs a known repo, use the throwaway-sandbox convention from the `forge` skill (create via `POST /repos`, delete after).

## Scenario 1: list all visible repos (live, read-only)

**Input:** `scripts/list_repos.py`

**Expected:** one `owner/name [private|public] description` line per visible repo, alphabetically; no raw JSON; private repos show as `[private]`.

## Scenario 2: routing boundary

**Input:** user asks to "list the repos I can see" vs. "list the issues in owner/repo".

**Expected:** repo discovery routes here; issue/PR work on a known repo routes to `forge-issue`/`forge-pr`.
