---
name: writing-skills
description: Author new Agent Skills in a repository's .agents/skills directory. Use when the user asks to create or add a skill, write SKILL.md, or extend the agent's capabilities with a new skill.
---

# Writing skills

Read [references/SPEC.md](references/SPEC.md) before writing any skill — it contains the authoritative Agent Skills specification.

## When to write a skill

Write a skill when a workflow needs repeatable, self-contained instructions that outgrow a prompt or a rule file:

- The task recurs and follows a stable procedure.
- Supporting files (references, templates, scripts) add real value.

Do **not** write a skill for one-off tasks, or for behavior that belongs in `AGENTS.md` or project conventions (general coding guidelines apply to every session anyway).

## Workflow

1. **Design first.** Draft the directory tree and describe what `SKILL.md` will contain. Get user feedback before building.
2. **Location.** Skills live in the current project's repo at `.agents/skills/<name>/`, committed and shared with the project's collaborators. If the skill is meant to be user/global (available across projects), add it to the user's dotfiles repo (`agent-dotfiles`) instead and follow that repo's instructions.
3. **Write `SKILL.md`.** Follow the spec (see SPEC.md). Keep it under 500 lines. The `description` must state *what it does* and *when to use it*, with concrete trigger keywords — this is the only routing signal.
4. **Progressive disclosure.** Move detail out of `SKILL.md` into `references/` (loaded on demand) or `scripts/`. Keep references one level deep from `SKILL.md`.
5. **Write regression scenarios.** Record the real-world test scenarios for the skill (inputs, steps, expected results) in `references/SCENARIOS.md`, so future edits can be verified against the same use cases.
6. **Validate.** Run `agentskills validate <skill-dir>` (see compatibility requirements in the testing-skills skill). Fix all errors.
7. **Test.** Use the `testing-skills` skill to verify the skill routes correctly and its instructions work end to end.
8. **Commit and PR.** Follow the project repo's conventions — typically a topic branch, conventional commits, atomic commits, then a pull request on the project's forge.

## Harness notes

Skills are portable across Agent Skills implementations. Where behavior is harness-specific, add a short section like the one below rather than making the whole skill harness-specific.

### Pi

- User skills are discovered in `~/.agents/skills/` and project skills in `.agents/skills/` (walked up to the repo root). Directories containing `SKILL.md` are found recursively.
- Unknown frontmatter fields warn but do not stop startup; keep frontmatter within the spec for portability.
- Skills load on model demand; `/skill:<name>` forces loading, and text after it is appended as a user request. `disable-model-invocation: true` hides a skill from automatic selection.
- After editing a skill during a session, run `/reload`.
