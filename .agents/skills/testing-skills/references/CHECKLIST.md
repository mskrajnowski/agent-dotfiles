# Skill test checklist

Copy this file and fill it in when running a full verification pass on a skill. Record pass/fail and notes per item.

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

- [ ] Skill is discovered by the harness (appears in pi `/skill:<name>` or startup diagnostics)
- [ ] Agent loads the skill on a representative trigger task
- [ ] Agent does **not** load the skill on a near-miss task
- [ ] No warnings about the skill at harness startup
- [ ] (If applicable) `disable-model-invocation` behaves as intended — `/skill:<name>` still works

## C. End-to-end

- [ ] Core workflow completed once on a realistic sample task using only the skill's instructions
- [ ] Every script in `scripts/` ran successfully; error paths handled gracefully (tested with missing/bad input)
- [ ] Instructions contain no missing steps or undefined terms
- [ ] Edge cases listed in the skill behave as documented
- [ ] After edits, `/reload` picked up the changes

## D. Packaging

- [ ] Skill stowed into `$HOME` via `install.sh` and discoverable there
- [ ] Committed on a topic branch with a conventional commit message
- [ ] PR opened against `forge.local/mskrajnowski/agent-dotfiles`

**Result:** PASS / FAIL — notes:
