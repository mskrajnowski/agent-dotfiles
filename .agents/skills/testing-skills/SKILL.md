---
name: testing-skills
description: Verify and test an Agent Skill — structure, routing, and end-to-end behavior. Use when a skill was just written or edited, when the user asks to test or verify a skill, or before opening a PR that adds a skill.
compatibility: Requires the agentskills CLI (skills-ref) for validation.
---

# Testing skills

Test a skill at three levels, in order. For a full verification pass, load [references/CHECKLIST.md](references/CHECKLIST.md); for quick checks (e.g. after a description tweak), the inline steps here are enough.

## 1. Structural validation

```bash
agentskills validate <skill-dir>
```

All errors must be fixed; warnings should be resolved or explicitly justified to the user.

## 2. Routing test

The `description` is the only routing signal. Verify the skill activates for the tasks it should and not for ones it shouldn't:

- Ask the agent to perform the skill's trigger task (e.g. "extract text from this PDF" for a PDF skill) and check whether it loads the skill.
- Ask a near-miss task (e.g. "convert this PNG" for the same skill) and check it does **not** load the skill.
- Watch harness startup diagnostics for warnings about the skill.
- For regression, reuse the scenarios recorded in the skill's `references/SCENARIOS.md` when they exist; else run representative trigger and near-miss prompts.

## 3. End-to-end dry run

Walk through the skill's own instructions on a realistic sample task:

- Run every script the skill references; verify they exit cleanly and handle missing arguments gracefully.
- Resolve every relative file reference from the skill root; fix broken paths.
- Perform the core workflow at least once and confirm the instructions are complete (no missing steps, no undefined terms).
- Check edge cases listed in the skill actually work.

At the end, present the results to the user directly (pass/fail per area and any notes) — do not persist test-report artifacts in the repo.

## Harness notes

Harness-specific behavior goes in short sections like this one, not in the generic flow.

### Pi

- Place the skill where pi discovers it (project `.agents/skills/`, or the dotfiles repo for global skills) before testing routing; run `/reload` after any edit.
- Run `/skill:<name>` to confirm the skill is discoverable.
- Routing can be tested in-session by launching a subagent with the trigger prompt (use the default model) and inspecting whether it loaded the skill.
