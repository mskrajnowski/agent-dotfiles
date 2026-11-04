---
name: forge-repo
description: Discover repositories on the user's forge — list repos visible to the authenticated user, search them by keyword. Use when the user asks what repos exist, to find a repo, or to list their repositories.
---

# Working with repositories

Scripts live in this skill's directory; run them via relative path. They are [uv inline-dependency scripts](https://docs.astral.sh/uv/guides/scripts/) — run them directly (`./scripts/foo.py`) or via `uv run --script scripts/foo.py`; **never** with a bare `python`/`python3` invocation, which skips uv's dependency resolution and fails with `ModuleNotFoundError`. All scripts use `curl --netrc` against `http://forge.local/api/v1` (see the `forge` skill for shared conventions). Each script prints only an agent-friendly summary — never raw JSON.

## Workflows

### List repositories

```bash
scripts/list_repos.py
```

Lists all repositories visible to the authenticated user (own, org, and collaborative). Prints `owner/name [private|public] description` per repo, alphabetically, description truncated. Takes no arguments.

## Conventions

- Use this skill to discover repos before operating on them — you need `<owner>/<repo>` for the `forge-issue` and `forge-pr` scripts.
- Repo visibility is what the API returns for the authenticated account, which may differ from the user's own account (see the `forge` skill's agent-identity note).
- For everything else a repo can do (issues, PRs, diffs), route to `forge-issue` or `forge-pr`.
