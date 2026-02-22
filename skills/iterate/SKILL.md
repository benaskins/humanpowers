---
name: iterate
description: Use when executing an implementation plan. Builds in TDD cycles with disciplined commits — one commit per plan step, no unrelated files swept in.
---

# Iterate

Execute a plan one step at a time. Each step is a TDD red/green/refactor cycle that ends with a clean commit.

1. Read the plan. Pick up the next incomplete step. If done, `/deploy` or ship it.
2. Red/green/refactor. Show test output at each stage.
3. Run `git status` — surface any unrelated files to the user before staging.
4. One commit per plan step. Stage only related files. Conventional commit message.
5. Go to 1.

Stop and surface to the user if:
- A step reveals a design question the plan didn't anticipate
- Tests are failing for reasons unrelated to the current step
- You've been going for 45 minutes

$ARGUMENTS
