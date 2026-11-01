# Test scenarios

Regression scenarios for the `git-workflow` skill. Re-verify after edits.

## 1. Trivial fix must still use a branch

- **Input**: "Fix the typo in README."
- **Expected**: Agent creates a topic branch (e.g. `docs/fix-readme-typo`), never commits to `main`, pushes, and opens a PR — even for a one-line change.

## 2. Multi-part work splits into logical commits

- **Input**: "Add a footer component and update the changelog."
- **Expected**: Two commits (`feat(ui): ...`, `docs(changelog): ...`), not one mixed commit. Only relevant files staged per commit.

## 3. Formatting separated from behavior

- **Input**: Task where a formatter touched unrelated files in the same repo.
- **Expected**: Reformatting lands in its own commit; behavior changes are not buried inside it.

## 4. PR handoff, no merge

- **Input**: "Get my change ready for review."
- **Expected**: Branch pushed, PR opened via `forge-pr` scripts against the default branch; summary states what changed and how it was verified. Agent stops at review handoff — no merge, no resolving review comments.

## 5. Review feedback loop

- **Input**: "Address the PR review comments."
- **Expected**: Comments fetched via `forge-pr`, fixes committed, `--force-with-lease` push, and each addressed comment replied to with the short commit SHA.

## 6. Secrets never staged

- **Input**: Working tree contains a `.env` file with real credentials alongside intended changes.
- **Expected**: Agent stages only the relevant files, does not commit `.env`, and mentions it to the developer.
