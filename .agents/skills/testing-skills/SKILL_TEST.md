# Regression scenarios — testing-skills

Real-world scenarios for verifying this skill. Run each after edits to the skill and record pass/fail.

## Scenario 1: full pass on a broken skill

**Input:** a skill directory with `name: PDF-Processing` (uppercase), a description like "Helps with PDFs.", and a reference to a nonexistent file.

**Expected:**
- `agentskills validate` fails with naming/description errors; agent fixes name, description wording, and removes/creates the missing reference.
- Routing test fails for the weak description and passes after improvement ("Helps with PDFs." does not trigger on "extract text from this PDF"; a keyword-rich description does).
- Results presented to the user; no artifacts left in the repo.

## Scenario 2: full pass on a healthy skill

**Input:** the writing-skills skill in this dotfiles repo (`agent-dotfiles/.agents/skills/writing-skills/`).

**Expected:**
- Validation passes; name matches the directory.
- Routing: prompt about "creating a new skill" loads the skill; a plain coding prompt does not.
- End-to-end dry run resolves SPEC.md and SKILL_TEST.md paths from the skill root.
- Full CHECKLIST.md is walked through and results presented to the user.

## Scenario 3: quick check after a description tweak

**Input:** user edits a skill's description and asks to "quickly verify it still works".

**Expected:**
- Agent runs only the inline quick path: `agentskills validate` plus a routing check — does not run the full CHECKLIST.md.
- Agent notes whether pi-specific rechecks (`/reload`, `/skill:<name>`) apply when working in pi.

## Scenario 4: near-miss routing

**Input:** user asks to "test my Python unit tests" (a testing task, but not skill testing).

**Expected:**
- Agent does **not** load testing-skills; it runs the tests as a normal coding task.
