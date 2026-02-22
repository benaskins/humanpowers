# Generic Claude Code Skills

Reusable skills that apply across all projects. Installed globally to `~/.claude/skills/` via symlinks.

## Skills

| Skill | Purpose |
|---|---|
| brainstorming | Explore intent, requirements, and design before building |
| debugging | Hypothesis-driven bug diagnosis |
| tdd | Test-driven development — red/green/refactor |
| verify | Evidence-based completion checks |

## Installation

```bash
just install-skills
```

This symlinks each skill folder from `skills/` into `~/.claude/skills/` so Claude Code discovers them globally.

## Convention

Every repo with Claude Code skills follows the same pattern:

- **Source of truth**: `skills/` directory in the repo (version-controlled)
- **Discovery**: `.claude/skills/` (symlinks, gitignored)
- **Install command**: `just install-skills`

Project-specific skills live in their own repo's `skills/` folder and symlink to `<repo>/.claude/skills/`. Generic skills (this repo) symlink to `~/.claude/skills/` for global availability.
