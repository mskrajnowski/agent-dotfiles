---
name: testing-skills
description: Verify and test an Agent Skill — structure, routing, and end-to-end behavior. Use when a skill was just written or edited, when the user asks to test or verify a skill, or before opening a PR that adds a skill.
license: MIT
metadata:
  author: mskrajnowski
---

# Testing skills

Test a skill at three levels, in order. For a full verification pass, load [references/CHECKLIST.md](references/CHECKLIST.md) and fill it in; for quick checks (e.g. after a description tweak), the inline steps here are enough.

## 1. Structural validation

```bash
agentskills validate <path-to-skill-dir>
```

Installed via mise (`pipx:skills-ref`). All errors must be fixed; warnings should be resolved or explicitly justified to the user.

## 2. Routing test

The `description` is the only routing signal. Verify the skill activates for the tasks it should and not for ones it shouldn't:

- Ask the agent to perform the skill's trigger task (e.g. "extract text from this PDF" for a PDF skill) and check whether it loads the skill.
- Ask a near-miss task (e.g. "convert this PNG" for the same skill) and check it does **not** load the skill.
- Watch startup diagnostics for warnings about the skill.

In pi specifically: run `/skill:<name>` to confirm the skill is discoverable, and check the startup diagnostics after `/reload`.

## 3. End-to-end dry run

Walk through the skill's own instructions on a realistic sample task:

- Run every script the skill references; verify they exit cleanly and handle missing arguments gracefully.
- Resolve every relative file reference from the skill root; fix broken paths.
- Perform the core workflow at least once and confirm the instructions are complete (no missing steps, no undefined terms).
- Check edge cases listed in the skill actually work.

For a test report artifact, copy `references/CHECKLIST.md` and record pass/fail per item.

## Harness notes

### Pi

- Place the skill where pi discovers it (`~/.agents/skills/` for user skills) before testing routing; run `/reload` after any edit.
- Routing can be tested in-session by launching a subagent with the trigger prompt (e.g. `scout` or `worker`) and inspecting whether it loaded the skill; subagents in this setup use `z-ai/glm-5.3-flash` by default.
- pi tolerates a `name` mismatch with the directory, but portable implementations may not — always validate with `agentskills validate`.
