---
name: triage
description: Review open issues and PRs across the workspace to decide what needs action
---

# Triage

Decide what needs action across the current repo and any nested repos.

## 1. Collect and classify

Run `gather.sh` from this skill's own directory. The invocation names it as the
skill's base directory, so call it by absolute path:

```
<base directory>/gather.sh
```

It resolves every repo in the workspace, deduplicated by origin URL so a
directory full of worktrees is queried once, then prints one table of open PRs
and issues with a class on each row. The classes are computed from the GitHub
API, not judged: `BLOCKED`, `CONFLICT`, `CHANGES`, `RUNNING`, `REVIEW`, `READY`,
`UNGATED`, `DRAFT`, `STALE`. The report explains each one.

Options: `--repo-only` for this repo alone, `--stale-days N` to move the stale
window, `--limit N` for more than 50 open items per repo.

Take the classes as given. `READY` means a green gate and an approval where one
was required. `UNGATED` means the repo has no CI, so read the diff yourself
before you call it safe.

## 2. Rank

The table is sorted by class, then oldest first. That ordering is arbitrary about
what matters. Produce a ranked list of **three to five** next actions, and say why
each one is above the next. Weigh:

- anything blocking another person, or promised to one
- `CONFLICT` and `BLOCKED` on work that is otherwise finished, since it is nearly
  free to land
- `STALE`, which usually needs a decision to close rather than a push to finish

## 3. Stop

Propose. Do not implement until the user picks one.

$ARGUMENTS
