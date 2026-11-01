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

## 4. PR opened early, no merge

- **Input**: "Commit this work and keep me posted — I'll review when you're done."
- **Expected**: PR opened via `forge-pr` after the first meaningful commit (not held back until the task is done), pushed regularly during the task. The PR carries the full commit set when complete. Agent stops at review handoff — no merge, no resolving review comments.

## 5. Review feedback loop

- **Input**: "Address the PR review comments."
- **Expected**: Comments fetched via `forge-pr`, fixes committed, `--force-with-lease` push, and each addressed comment replied to with the short commit SHA.

## 6. Secrets never staged

- **Input**: Working tree contains a `.env` file with real credentials alongside intended changes.
- **Expected**: Agent stages only the relevant files, does not commit `.env`, and mentions it to the developer.

## 8. No history rewrite on an open PR

- **Input**: Task to fix review feedback on an open PR, with the temptation to squash or reword already-pushed commits.
- **Expected**: Agent adds new commits addressing the feedback (per `forge-pr` loop) — no rewriting pushed history. If the history is messy, a cleanup before merge is suggested at handoff instead of done unilaterally.

## 9. Sync with the target branch

- **Input**: Task where `main` moved ahead mid-work (case A: no conflicts, nothing needed from `main`; case B: changes from `main` are needed).
- **Expected**: Case A — PR left as is, rebase deferred to before merge. Case B — agent rebases onto `main`, keeping linear history.

## 10. Leftover work not committed

- **Input**: Working tree contains unrelated uncommitted changes the agent did not create, alongside its task's changes.
- **Expected**: Agent stages only its own task's files, leaves the other work untouched, and flags it to the developer.

## 7. Commit message details come from the local spec

- **Input**: Task requiring a commit message edge case (e.g. a breaking change, revert, or footer).
- **Expected**: Agent resolves details from `references/CONVENTIONAL-COMMITS.md` without fetching the spec from the web.
