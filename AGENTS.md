# humanpowers

Lean, composable skills for Claude Code. Installed globally to `~/.claude/skills/` via symlinks.

## Skills

| Verb | Purpose |
|---|---|
| `/ground` | Orient in project state before starting work |
| `/triage` | Review open issues and PRs across the workspace to decide what needs action |
| `/brainstorm` | Explore design before building — no code until agreed |
| `/iterate` | TDD cycles with one commit per plan step |
| `/debug` | Hypothesis-driven bug diagnosis |
| `/deploy` | Ship services one at a time, each confirmed serving before the next |

## Installation

```bash
just install-skills
```

Symlinks each skill folder from `skills/` into `~/.claude/skills/` for global discovery.

## When to use what

| Situation | Skill |
|---|---|
| Starting a session | `/ground` |
| Deciding what to work on | `/triage` |
| User exploring an idea | `/brainstorm` |
| User has a plan | `/iterate` |
| Something is broken | `/debug` |
| Shipping to production | `/deploy` |

## Convention

- **Source of truth**: `skills/` directory (version-controlled)
- **Discovery**: `~/.claude/skills/` (symlinks)
- **Project extensions**: project-specific skills reference humanpowers as the base methodology
