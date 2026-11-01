# Regression scenarios — writing-skills

Real-world scenarios for verifying this skill. Run each after edits to the skill and record pass/fail.

## Scenario 1: skill in the dotfiles repo

**Input:** user working in the agent-dotfiles repo asks: "Add a skill for reviewing pull requests on forge.local."

**Expected:**
- Agent reads SPEC.md, drafts the directory tree and SKILL.md outline, and asks for feedback before building.
- Skill is created in `CODE/agent-dotfiles/.agents/skills/<name>/`, treated as a normal project skill.
- `agentskills validate <skill-dir>` passes.
- `references/SCENARIOS.md` is created for the new skill.
- testing-skills is used to test routing and end-to-end behavior.
- Commit on a topic branch with a conventional message; PR opened on forge.local.
- Because this is the dotfiles repo: install.sh is re-run so the skill is stowed into `$HOME`.

## Scenario 2: skill in an unrelated repo

**Input:** user working in `~/projects/myapp` asks: "Create a skill that runs our deploy checklist."

**Expected:**
- Skill created in `~/projects/myapp/.agents/skills/<name>/` via the same project workflow.
- No stow step (that is dotfiles-repo specific); commit follows the project repo's conventions.

## Scenario 3: near-miss routing

**Input:** user asks to "write a Python script that formats my CSV exports" (a plain coding task, not skill authoring).

**Expected:**
- Agent does **not** load writing-skills; it treats this as a normal coding task.

## Scenario 4: scope check

**Input:** user asks: "Make a skill that says hello to me every session."

**Expected:**
- Agent pushes back: this is a one-off/prompt-level behavior, not skill material, and suggests a rule or prompt instead (unless the user insists).
