---
name: ground
description: Orient in project state before starting work
---

# Ground

Ground yourself in the current project state before starting any work.

## 1. Collect the state

Run `gather.sh` from this skill's own directory. The invocation names it as the
skill's base directory, so call it by absolute path:

```
<base directory>/gather.sh
```

It prints one fixed report: repo identity, whether this is a main checkout or a
worktree, divergence from origin after a fetch, the working tree, the last ten
commits, every nested repo holding work, open PRs and issues, the repo's test
command, and warnings.

Options: `--no-github` when offline or `gh` has no auth, `--repo-only` to skip
nested repos at a workspace root.

The script is read-only. **It never rebases, checks out, resets or stashes**, and
neither do you during grounding. If the report says the branch is behind, say so
and offer to rebase. Do not rebase to find out.

## 2. Read the project's own instructions

`CLAUDE.md`, `AGENTS.md`, and any nested copies the report's repo list implies.
These outrank anything in this skill.

## 3. Run the test suite

The report names the command it detected. Run it and report the result. Flag any
failure that was already there, so it does not get attributed to work that has
not started.

## 4. Summarise, then stop

Say where the project left off, what is in flight, and anything that blocks a
start. Name the repo any proposed change belongs in.

Then **stop**. Do not start work until the user confirms.

Once grounded, `/brainstorm` the task.

$ARGUMENTS
