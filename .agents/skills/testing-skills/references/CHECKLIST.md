# Skill test checklist

Load this file when running a full verification pass on a skill. Record pass/fail and notes per item, then present the results to the user.

**Skill under test:** `<name>` at `<path>` — Date: `<date>`

## A. Structure

- [ ] `agentskills validate <path>` exits clean (no errors)
- [ ] `name` matches the parent directory name
- [ ] `description` states both what the skill does and when to use it, with concrete trigger keywords
- [ ] `SKILL.md` body is under 500 lines
- [ ] All referenced files exist and paths are relative to the skill root, one level deep
- [ ] Scripts are self-contained (or dependencies documented) and executable
- [ ] Assets (templates, data) are coherent and usable

## B. Routing

- [ ] Skill is discovered by the harness (appears in skill listings)
- [ ] Agent loads the skill on a representative trigger task
- [ ] Agent does **not** load the skill on a near-miss task
- [ ] No warnings about the skill at harness startup
- [ ] (If applicable) `disable-model-invocation` behaves as intended

## C. End-to-end

- [ ] Core workflow completed once on a realistic sample task using only the skill's instructions
- [ ] Every script in `scripts/` ran successfully; error paths handled gracefully (tested with missing/bad input)
- [ ] Instructions contain no missing steps or undefined terms
- [ ] Edge cases listed in the skill behave as documented
- [ ] Results presented to the user; no test-report artifacts left in the repo

## D. Regression scenarios

- [ ] `references/SCENARIOS.md` exists and covers the skill's main use cases
- [ ] Scenarios were executed and passed (re-run the scenarios from SCENARIOS.md)

## E. Packaging

- [ ] Skill committed in the right location (project repo or dotfiles repo, per the writing-skills workflow)
- [ ] User skills: stowed into `$HOME` and discoverable there
- [ ] Commit on a topic branch with a conventional commit message
- [ ] PR opened where applicable

**Result:** PASS / FAIL — notes:
