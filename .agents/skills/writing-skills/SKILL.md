---
name: writing-skills
description: Author new Agent Skills — user skills for the dotfiles repo and project skills for any repository. Use when the user asks to create or add a skill, write SKILL.md, or extend the agent's capabilities with a new skill.
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
2. **Decide the location.** Skills are Agent Skills directories placed in a skills-discovery location:
   - **Project skills** — for repository-specific tasks: `CODE/.agents/skills/<name>/`. Committed in the project repo and shared with its collaborators.
   - **User skills** — for cross-project tasks: the user's dotfiles repo at `.agents/skills/<name>/`, installed into `$HOME` via GNU stow.
   If the user did not specify, ask which one fits; cross-project workflows go in the dotfiles repo.
3. **Write `SKILL.md`.** Follow the spec (see SPEC.md). Keep it under 500 lines. The `description` must state *what it does* and *when to use it*, with concrete trigger keywords — this is the only routing signal.
4. **Progressive disclosure.** Move detail out of `SKILL.md` into `references/` (loaded on demand) or `scripts/`. Keep references one level deep from `SKILL.md`.
5. **Write regression scenarios.** Record the real-world test scenarios for the skill (inputs, steps, expected results) in `references/SCENARIOS.md`, so future edits can be verified against the same use cases.
6. **Validate.** Run `agentskills validate <skill-dir>` (see compatibility requirements in the testing-skills skill). Fix all errors.
7. **Test.** Use the `testing-skills` skill to verify the skill routes correctly and its instructions work end to end.
8. **Commit.**
   - *Project skill:* commit to the project repo per its conventions (typically a topic branch and PR).
   - *User skill:* commit in the dotfiles repo per its `AGENTS.md` commit rules (topic branch, conventional commits, atomic commits), stow it into `$HOME` by re-running the dotfiles `install.sh`, then open a pull request on the user's forge (`forge.local`, Forgejo — API at `http://forge.local/api/v1`, auth via `~/.netrc`).

## Harness notes

Skills are portable across Agent Skills implementations. Where behavior is harness-specific, add a short section like the one below rather than making the whole skill harness-specific.

### Pi

- User skills are discovered in `~/.agents/skills/` and project skills in `.agents/skills/` (walked up to the repo root). Directories containing `SKILL.md` are found recursively.
- Unknown frontmatter fields warn but do not stop startup; keep frontmatter within the spec for portability.
- Skills load on model demand; `/skill:<name>` forces loading, and text after it is appended as a user request. `disable-model-invocation: true` hides a skill from automatic selection.
- After editing a skill during a session, run `/reload`.
