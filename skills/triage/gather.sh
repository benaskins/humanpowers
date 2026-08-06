#!/usr/bin/env bash
# Classify every open PR and issue across the workspace, as one fixed table.
#
# Read-only, and it does not even fetch: every figure comes from the GitHub API,
# so a stale local checkout cannot skew it.
#
# The classes are computed, not judged. "Ready" means a green gate and an approval
# where one was required, not an impression. What the caller decides is the order
# to work in.
#
# Usage: gather.sh [--repo-only] [--stale-days N] [--limit N]
#   --repo-only     this repo alone, even at a workspace root
#   --stale-days N  age in days with no update that counts as stale (default 30)
#   --limit N       maximum open items to pull per repo per kind (default 50)
set -euo pipefail

stale_days=30
limit=50
want_workspace=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-only) want_workspace=0; shift ;;
        --stale-days) stale_days="${2:?--stale-days needs a number}"; shift 2 ;;
        --limit) limit="${2:?--limit needs a number}"; shift 2 ;;
        -h|--help)
            echo "usage: gather.sh [--repo-only] [--stale-days N] [--limit N]"
            echo "  --repo-only     this repo alone, even at a workspace root"
            echo "  --stale-days N  days with no update that count as stale (default 30)"
            echo "  --limit N       max open items per repo per kind (default 50)"
            exit 0
            ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
done

[[ "$stale_days" =~ ^[0-9]+$ ]] || { echo "--stale-days must be a number" >&2; exit 1; }
[[ "$limit" =~ ^[0-9]+$ ]] || { echo "--limit must be a number" >&2; exit 1; }

command -v gh >/dev/null 2>&1 || { echo "gh is not installed." >&2; exit 1; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository: $PWD" >&2; exit 1; }

root="$(git rev-parse --show-toplevel)"
cd "$root"

# --- which repos ------------------------------------------------------------

# Keyed by the origin URL, not the directory. A workspace of worktrees holds many
# directories that are all the same GitHub repo, and querying each one would
# multiply the API calls and print every PR once per worktree.
declare -a repos=()
seen=""

add_repo() {
    local dir="$1" url slug
    url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
    [[ -n "$url" ]] || return 0
    # git@host:owner/name.git and https://host/owner/name.git both reduce to
    # owner/name, which is what gh wants.
    slug="$(printf '%s' "$url" | sed -E 's|^git@[^:]+:||; s|^https?://[^/]+/||; s|\.git$||')"
    [[ "$slug" == */* ]] || return 0
    case "$seen" in
        *"|$slug|"*) return 0 ;;
    esac
    seen="${seen}|${slug}|"
    repos+=("$slug")
}

add_repo "$root"
if [[ "$want_workspace" -eq 1 ]]; then
    while IFS= read -r d; do
        add_repo "$d"
    done < <(find . -mindepth 2 -maxdepth 2 -name .git -exec dirname {} \; 2>/dev/null | sort)
fi

# --- classification ---------------------------------------------------------

# One jq program, so every repo is classified the same way.
#
# BLOCKED before READY: a PR can carry an approval and a red gate at once, and
# calling that ready is the error this exists to prevent.
# shellcheck disable=SC2016  # $pr is jq's variable, not the shell's
pr_jq='
  def age: (now - (.updatedAt | fromdateiso8601)) / 86400 | floor;
  def checks: [.statusCheckRollup[]? | select(.__typename == "CheckRun")];
  def failed: [checks[] | select(.conclusion | IN("FAILURE", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED"))] | length;
  def running: [checks[] | select(.status != "COMPLETED")] | length;
  .[] |
  . as $pr |
  (if .isDraft then "DRAFT"
   elif failed > 0 then "BLOCKED"
   elif .mergeable == "CONFLICTING" then "CONFLICT"
   elif running > 0 then "RUNNING"
   elif .reviewDecision == "CHANGES_REQUESTED" then "CHANGES"
   elif .reviewDecision == "APPROVED" then "READY"
   elif .reviewDecision == "REVIEW_REQUIRED" then "REVIEW"
   elif (checks | length) == 0 then "UNGATED"
   else "READY"
   end) as $class |
  [$class, (age | tostring), ("#" + (.number | tostring)), .author.login, .title] |
  @tsv
'

issue_jq='
  def age: (now - (.updatedAt | fromdateiso8601)) / 86400 | floor;
  .[] |
  [(if (.assignees | length) > 0 then "ASSIGNED" else "OPEN" end),
   (age | tostring), ("#" + (.number | tostring)), .author.login, .title] |
  @tsv
'

# STALE overrides whatever the gate says, because an item nobody has touched in a
# month needs a decision about the item rather than a merge.
emit() {
    local repo="$1" rows="$2"
    [[ -n "$rows" ]] || return 0
    # The owner is dropped from the column: an owner/name slug is wide enough to
    # break the alignment of every row, and SCOPE above prints the full slugs.
    printf '%s\n' "$rows" | awk -F'\t' -v repo="${repo##*/}" -v stale="$stale_days" '
        NF >= 5 {
            class = $1
            if ($2 + 0 >= stale) class = "STALE"
            printf "%-9s %-5s %-30s %-7s %-14s %s\n", class, $2 "d", repo, $3, $4, $5
        }'
}

# --- report -----------------------------------------------------------------

echo "== SCOPE"
echo "repos: ${#repos[@]} (deduplicated by origin URL)"
printf "  %s\n" "${repos[@]}"
echo "stale: no update in $stale_days day(s)"
echo

printf "%-9s %-5s %-30s %-7s %-14s %s\n" "CLASS" "AGE" "REPO" "REF" "AUTHOR" "TITLE"

# One subshell per repo, because the two queries are network-bound and independent.
# Twelve repos took 16s in sequence and about 3s this way. Each writes to its own
# files and the parent assembles them in order after `wait`, so the report does not
# depend on which repo answered first.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for i in "${!repos[@]}"; do
    (
        slug="${repos[$i]}"
        if out=$(gh pr list --repo "$slug" --state open --limit "$limit" \
                    --json number,title,author,isDraft,updatedAt,reviewDecision,mergeable,statusCheckRollup \
                    --jq "$pr_jq" 2>&1); then
            emit "$slug" "$out" > "$tmp/$i.pr"
        else
            echo "  $slug (PRs): ${out}" > "$tmp/$i.err"
        fi

        if out=$(gh issue list --repo "$slug" --state open --limit "$limit" \
                    --json number,title,author,updatedAt,assignees \
                    --jq "$issue_jq" 2>&1); then
            emit "$slug" "$out" > "$tmp/$i.issue"
        else
            echo "  $slug (issues): ${out}" >> "$tmp/$i.err"
        fi
    ) &
done
wait

pr_rows=""
issue_rows=""
failures=""
for i in "${!repos[@]}"; do
    [[ -s "$tmp/$i.pr" ]] && pr_rows+="$(cat "$tmp/$i.pr")"$'\n'
    [[ -s "$tmp/$i.issue" ]] && issue_rows+="$(cat "$tmp/$i.issue")"$'\n'
    [[ -s "$tmp/$i.err" ]] && failures+="$(cat "$tmp/$i.err")"$'\n'
done

# Sorted by class so the same classes read together, then oldest first inside a
# class, because age is the tie-break a human would apply anyway.
sort_rows() {
    grep -v '^[[:space:]]*$' | sort -k1,1 -k2,2nr
}

echo
echo "-- PULL REQUESTS"
if printf '%s' "$pr_rows" | grep -q '[^[:space:]]'; then
    printf '%s' "$pr_rows" | sort_rows
else
    echo "none open"
fi

echo
echo "-- ISSUES"
if printf '%s' "$issue_rows" | grep -q '[^[:space:]]'; then
    printf '%s' "$issue_rows" | sort_rows
else
    echo "none open"
fi

echo
echo "== CLASSES"
cat <<'LEGEND'
BLOCKED   a required check failed
CONFLICT  will not merge into its base as it stands
CHANGES   a reviewer asked for changes
RUNNING   checks still going; nothing to decide yet
REVIEW    waiting on a review that the repo requires
READY     green, and approved where an approval was required
UNGATED   nothing ran and nothing was required: no CI on this repo, so "green"
          says nothing. Read it yourself.
DRAFT     not offered for review yet
ASSIGNED  issue with an assignee
OPEN      issue with none
STALE     no update inside the window, whatever else is true
LEGEND

if [[ -n "$failures" ]]; then
    echo
    echo "== REPOS THAT DID NOT ANSWER"
    printf '%s' "$failures"
    echo "(a repo with issues disabled, or no access, reports here rather than"
    echo " vanishing from the counts)"
fi
