---
name: triage
description: Review open issues and PRs across the workspace to decide what needs action
---

# Triage

Review open work across the current repo and any nested repos in the workspace.

1. For each repo, run `gh issue list` and `gh pr list` with fields to classify: author, labels, age, last update, CI/review state
2. Classify each item:
   - **Ready to merge** — PR approved, CI green
   - **Needs user review** — awaiting the user
   - **In flight** — recent activity, still open
   - **Stale** — no activity >30 days
3. Surface anything blocking others or previously committed to
4. Propose a ranked next-action list (3-5 items). No implementation until the user picks one.

$ARGUMENTS
