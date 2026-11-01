---
name: writing-skills
description: Author new Agent Skills for this dotfiles repo. Use when the user asks to create a skill, add a skill, write SKILL.md, or extend the agent's capabilities with a new skill.
license: MIT
metadata:
  author: mskrajnowski
---

# Writing skills

Read [references/SPEC.md](references/SPEC.md) before writing any skill — it contains the authoritative Agent Skills specification. Start from [assets/SKILL.template.md](assets/SKILL.template.md).

## When to write a skill

Write a skill when a workflow needs repeatable, self-contained instructions that outgrow a prompt or a rule file:

- The task recurs and follows a stable procedure.
- The instructions are useful across projects, not one-off.
- Supporting files (references, templates, scripts) add real value.

Do **not** write a skill for one-off tasks, or for behavior that belongs in `AGENTS.md` (general coding guidelines apply to every session anyway).

## Workflow

1. **Design first.** Draft the directory tree and describe what `SKILL.md` will contain. Get user feedback before building. Skills live in `.agents/skills/<name>/` in this repo (mirrors `$HOME`; see install.sh).
2. **Write `SKILL.md`.** Follow the spec (see SPEC.md). Keep it under 500 lines. The `description` must state *what it does* and *when to use it*, with concrete trigger keywords — this is the only routing signal.
3. **Progressive disclosure.** Move detail out of `SKILL.md` into `references/` (loaded on demand), `assets/` (templates), or `scripts/`. Keep references one level deep from `SKILL.md`.
4. **Validate.** Run `agentskills validate .agents/skills/<name>` (installed via mise, `pipx:skills-ref`). Fix all errors.
5. **Test.** Use the `testing-skills` skill to verify the skill routes correctly and its instructions work end to end.
6. **Install.** From the repo root, re-run `install.sh` to stow the new skill into `$HOME`.
7. **Commit and PR.** Follow the commit rules in `AGENTS.md` (topic branch, conventional commits, atomic commits). This repo's remote is `forge.local/mskrajnowski/agent-dotfiles`; open a pull request there.

## Harness notes

Skills are portable across Agent Skills implementations. Where behavior is harness-specific, add a short section like the one below rather than making the whole skill harness-specific.

### Pi

- User skills are discovered in `~/.agents/skills/` and project skills in `.agents/skills/` (walked up to the repo root). Directories containing `SKILL.md` are found recursively.
- `name` should match the parent directory; pi tolerates a mismatch, but portable implementations may not.
- Unknown frontmatter fields warn but do not stop startup; keep frontmatter within the spec for portability.
- Skills load on model demand; `/skill:<name>` forces loading, and text after it is appended as a user request. `disable-model-invocation: true` hides a skill from automatic selection.
- After editing a skill during a session, run `/reload`.
