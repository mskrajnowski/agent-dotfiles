# Agent Skills specification

Source: https://agentskills.io/specification

## Directory structure

A skill is a directory containing, at minimum, a `SKILL.md` file:

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation
├── assets/           # Optional: templates, resources
└── ...               # Any additional files or directories
```

## `SKILL.md` format

The `SKILL.md` file must contain YAML frontmatter followed by Markdown content.

### Frontmatter

| Field | Required | Constraints |
| - | - | - |
| `name` | Yes | Max 64 characters. Lowercase letters, numbers, and hyphens only. Must not start or end with a hyphen. |
| `description` | Yes | Max 1024 characters. Non-empty. Describes what the skill does and when to use it. |
| `license` | No | License name or reference to a bundled license file. |
| `compatibility` | No | Max 500 characters. Indicates environment requirements (intended product, system packages, network access, etc.). |
| `metadata` | No | Arbitrary key-value mapping (string keys to string values). |
| `allowed-tools` | No | Space-separated string of pre-approved tools the skill may use. (Experimental) |

Minimal example:

```markdown
---
name: skill-name
description: A description of what this skill does and when to use it.
---
```

### `name` field

* 1–64 characters
* Only lowercase alphanumeric characters (`a-z`, `0-9`) and hyphens (`-`)
* Must not start or end with a hyphen
* Must not contain consecutive hyphens
* Must match the parent directory name

Invalid examples: `PDF-Processing` (uppercase), `-pdf` (leading hyphen), `pdf--processing` (consecutive hyphens).

### `description` field

* 1–1024 characters
* Should describe both what the skill does and when to use it
* Should include specific keywords that help agents identify relevant tasks

Good: `Extracts text and tables from PDF files, fills PDF forms, and merges multiple PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction.`

Poor: `Helps with PDFs.`

### `license` field

Short license name or reference to a bundled license file, e.g. `license: Proprietary. LICENSE.txt has complete terms`.

### `compatibility` field

1–500 characters if provided. Only include when the skill has specific environment requirements (intended product, system packages, network access). Most skills do not need it. Example: `Requires Python 3.14+ and uv`.

### `metadata` field

Map from string keys to string values; use reasonably unique key names to avoid conflicts. Example:

```yaml
metadata:
  author: example-org
  version: "1.0"
```

### `allowed-tools` field

Space-separated string of pre-approved tools. Experimental; support varies between implementations. Example: `allowed-tools: Bash(git:*) Bash(jq:*) Read`.

### Body content

No format restrictions. Recommended sections: step-by-step instructions, examples of inputs and outputs, common edge cases. The agent loads the entire file on activation — split longer content into referenced files.

## Optional directories

### `scripts/`

Executable code agents can run. Scripts should be self-contained or clearly document dependencies, include helpful error messages, and handle edge cases gracefully.

### `references/`

Documentation loaded on demand: `REFERENCE.md`, `FORMS.md`, domain-specific files. Keep individual files focused — smaller files mean less context use.

### `assets/`

Static resources: templates, images, data files (lookup tables, schemas).

## Progressive disclosure

1. **Metadata** (~100 tokens): `name` and `description` loaded at startup for all skills
2. **Instructions** (< 5000 tokens recommended): full `SKILL.md` body loaded on activation
3. **Resources** (as needed): files in `scripts/`, `references/`, `assets/` loaded only when required

Keep the main `SKILL.md` under 500 lines.

## File references

Use relative paths from the skill root. Keep references one level deep from `SKILL.md`; avoid deeply nested reference chains:

```markdown
See [the reference guide](references/REFERENCE.md) for details.
Run the extraction script: scripts/extract.py
```

## Validation

```bash
skills-ref validate ./my-skill
```

Checks that frontmatter is valid and naming conventions are followed.
