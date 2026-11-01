---
# name: REQUIRED — lowercase a-z, 0-9, hyphens; max 64 chars; must match the parent
#   directory name; no leading/trailing/consecutive hyphens.
name: my-skill
# description: REQUIRED — max 1024 chars. State what the skill does AND when to use
#   it, with concrete keywords that help the agent route the task to this skill.
description: Describe what this skill does and when to use it. Include trigger keywords the agent will see in the user's request.
# license: OPTIONAL — license name or reference to a bundled license file.
license: MIT
# compatibility: OPTIONAL — max 500 chars; only if the skill needs specific
#   environment requirements (system packages, network access, etc.). Usually omit.
# compatibility: Requires Python 3 and network access.
# metadata: OPTIONAL — string-to-string map; use unique key names.
metadata:
  author: mskrajnowski
# allowed-tools: OPTIONAL — space-separated pre-approved tools (experimental;
#   support varies between implementations).
# allowed-tools: Bash(git:*) Read
---

# Skill title

One-line summary of the skill's purpose.

## When to use this skill

Describe the triggering conditions concretely (delete this section if the
description already covers routing unambiguously).

## Workflow

1. Step-by-step instructions for the task.
2. Keep steps imperative and specific; state assumptions explicitly.
3. If a step needs deep detail, put it in a reference file and link it:
   See [references/REFERENCE.md](references/REFERENCE.md).

## Examples

Show at least one concrete input → output example.

## Edge cases

List the failure modes and how to handle them.

## Harness notes

Harness-specific behavior (pi, Claude Code, etc.) goes in short sections here,
not as the body of the skill.

<!-- Delete all HTML comments before finishing. Keep the body under 500 lines;
     move detail to references/. -->
