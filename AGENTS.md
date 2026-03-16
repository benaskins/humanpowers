# humanpowers

Lean, composable skills for Claude Code. Installed globally to `~/.claude/skills/` via symlinks.

## Skills

| Verb | Purpose |
|---|---|
| `/ground` | Orient in project state before starting work |
| `/brainstorm` | Explore design before building — no code until agreed |
| `/iterate` | TDD cycles with one commit per plan step |
| `/debug` | Hypothesis-driven bug diagnosis |
| `/verify` | Evidence-based completion checks |
| `/deploy` | End-to-end service deploy with health verification |

## Installation

```bash
just install-skills
```

Symlinks each skill folder from `skills/` into `~/.claude/skills/` for global discovery.

## Convention

- **Source of truth**: `skills/` directory (version-controlled)
- **Discovery**: `~/.claude/skills/` (symlinks)
- **Project extensions**: project-specific skills reference humanpowers as the base methodology
