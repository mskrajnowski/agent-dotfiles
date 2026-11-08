# Agent dotfiles repo

## About this repo

The main goal of this repo is to provide base configuration for the environment the agent is working in. That includes tools installed through mise and configuration as various dotfiles.

When the user asks to add something globally, include it here:

- Global skills go in `agent-dotfiles/.agents/skills/`
- Global instructions go in `agent-dotfiles/.agents/AGENTS.md`
- Global tools go in `agent-dotfiles/.config/mise/`

The repo mirrors `$HOME` and is installed as a single GNU stow package: run `./install.sh` from the repo root after changing files so everything (including skills) is linked into `$HOME` and discoverable. The stow ignore list lives in `.stow-local-ignore`.

## Keeping harnesses in sync

This repo configures several agent harnesses (Pi and Claude Code today, more later). Pi is
the reference: define skills and subagents for Pi first, then mirror the change to every
other harness in the same change.

### Skills

- Canonical skills live in `.agents/skills/<name>/` and are shared, not copied.
- Harnesses that don't read `.agents/skills` directly need a per-skill symlink, e.g.
  `.claude/skills/<name> -> ../../.agents/skills/<name>`. Add the symlink in every such
  harness's skills directory when you add a skill.
- `install.sh` pre-creates each harness skills directory so stow links skills individually
  instead of folding the directory.

### Subagents

- Canonical agent definitions live in `.pi/agent/agents/<name>.md`. Edit them there first.
- Agents are copied, not symlinked, because each harness has different frontmatter (tool
  names, model aliases, harness-specific fields). Copy the file into each harness's agent
  directory (`.claude/agents/<name>.md`, ...) and adapt the frontmatter only.
- Keep the body (system prompt) in sync by hand. Translate harness tool names
  (`read` -> `Read`, `web_search` -> `WebSearch`, ...) and drop mechanisms the harness does
  not have (`contact_supervisor`, `source_check`, forked context), but keep the guidance,
  structure, and output format equivalent. Update every copy in the same change.
- The same agents are enabled in every harness: `scout`, `researcher`, `worker`,
  `reviewer`, `oracle`, `delegate`, `evidence-auditor`, and `vision`. In Pi, the files in
  `.pi/agent/agents/` take over from the `pi-subagents` built-ins and `advertise: true`
  publishes them to the parent prompt; `subagents.disableBuiltins` in
  `.pi/agent/settings.json` disables the remaining package agents. In Claude Code an agent
  is enabled by its file in `.claude/agents/`. Add or remove an agent in both harnesses
  together.
- Subagents map to three shared model tiers, kept comparable across harnesses:

  | Tier | Pi | Claude |
  |---|---|---|
  | fast/cheap | `openrouter/z-ai/glm-5.3-flash`, `thinking: low` | `model: haiku` |
  | default | `openrouter/z-ai/glm-5.3-flash`, `thinking: high` | `model: sonnet` |
  | slow/expensive | `openrouter/z-ai/glm-5.3`, `thinking: high` | `model: opus` |

  Tier assignments: fast — `scout`, `researcher`; default — `worker`, `reviewer`,
  `evidence-auditor`; slow — `oracle`. When you add an agent, pick a tier and set both
  harnesses accordingly. `subagents.defaultModel` in `.pi/agent/settings.json` matches the
  default tier and fills agents without explicit frontmatter; the default thinking level
  comes from the top-level `defaultThinkingLevel`, which also sets the main session's
  default.
- `delegate` is the exception: it follows the parent session's model (`model: inherit` in
  Pi, no `model` field in Claude) instead of a tier.
- `vision` is the other exception: it stays on `openrouter/z-ai/glm-5.3-flash`
  (Pi, `thinking: off`) / `haiku` (Claude) rather than the fast/cheap tier. Chosen
  empirically: glm-5.3-flash reads screenshots at full resolution (no provider-side
  downscale), while deepseek's effective image input is downscaled to roughly 400px,
  which loses small text; thinking level made no accuracy difference.
- The `vision` subagent instructions are inlined in both agent files rather than in a
  shared skill, so the child skips an extra skill-read roundtrip.
