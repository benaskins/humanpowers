# humanpowers

Lean, composable skills for Claude Code. Not superpowers — humanpowers.

Six skills, all under 20 lines, designed to be used as verbs.

## The chain

```
/ground → /brainstorm → /iterate → /verify
```

Start by grounding yourself in the project. Brainstorm the design. Iterate through implementation in TDD cycles. Verify with evidence.

Two standalone workflows chain in when needed:

```
/debug → /verify
/deploy
```

## Skills

| Verb | What it does |
|---|---|
| `/ground` | Orient in project state before starting work |
| `/brainstorm` | Explore the design space through conversation — no code until agreed |
| `/iterate` | Execute a plan in TDD red/green/refactor cycles, one commit per step |
| `/debug` | Hypotheses before fixes, boring explanations before clever ones |
| `/verify` | Show evidence, not assertions |
| `/deploy` | Deploy services end-to-end with health verification |

## Composability

Skills reference each other as verbs:

- `/ground` finishes with "now `/brainstorm`"
- `/brainstorm` starts with "`/ground` yourself first" and finishes with "now `/iterate`"
- `/debug` ends with "`/verify`"
- `/iterate` ships with "`/deploy`"

This means invoking any skill can pull in the others naturally. You can also enter the chain at any point — `/iterate` works fine without `/brainstorm` if you already have a plan.

## Extending with project skills

Humanpowers skills are generic. Project-specific skills extend them with local tool knowledge:

```
/aurelia-debug  → follows /debug, adds aurelia CLI commands
/aurelia-deploy → follows /deploy, adds aurelia service mesh steps
/lamina-workspace → extends /ground, adds lamina workspace tools
```

To write a project extension, create a skill that says "Follow `/deploy` — here's how each step works with [your tool]."

## Install

```bash
git clone https://github.com/benaskins/humanpowers.git
cd humanpowers
just install-skills
```

This symlinks each skill into `~/.claude/skills/` for global availability.

## Philosophy

- **Trust the LLM.** Don't explain what TDD is. Don't list rationalization red flags. State the process, not the pedagogy.
- **Compose as verbs.** Skills are actions, not documents. `/ground`, `/brainstorm`, `/iterate` — not "grounding-checklist", "brainstorming-framework", "implementation-methodology".
- **Stay lean.** If a skill is over 20 lines, it's trying to do too much. The right amount of instruction is the minimum that changes behaviour.
- **Extend, don't fork.** Project-specific skills reference humanpowers as the base methodology, adding only the tool-specific knowledge the agent needs.

## License

MIT
