---
name: ground
description: Orient in project state before starting work
---

# Ground

Ground yourself in the current project state before starting any work.

1. Read CLAUDE.md and any project-level CLAUDE.md files
2. Identify which repo you're in and where changes belong
3. Sync with origin: `git fetch origin && git rebase origin/main` — report if there were upstream changes
4. Run `git status` in each repo in the current workspace — summarize what's in progress
5. Check for uncommitted changes, stale branches, or in-flight work
6. Run `git log --oneline -10` to show recent work and provide context on where the project left off
7. Run the project's test suite and report results — flag any pre-existing failures
8. Summarize the current state concisely
9. Do NOT start any work until the user confirms

Once grounded, `/brainstorm` the task.

$ARGUMENTS
