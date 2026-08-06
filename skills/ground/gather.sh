#!/usr/bin/env bash
# Collect the state a session needs before it starts work, as one fixed report.
#
# Read-only. It fetches, which is a network read, and it never checks out,
# rebases, resets, stashes or commits. A grounding step that mutates the tree is
# how a parallel session loses its branch.
#
# Usage: gather.sh [--no-github] [--repo-only]
#   --no-github  skip the gh calls (offline, or no gh auth)
#   --repo-only  report this repo alone, even at a workspace root
set -euo pipefail

want_github=1
want_workspace=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-github) want_github=0; shift ;;
        --repo-only) want_workspace=0; shift ;;
        -h|--help)
            echo "usage: gather.sh [--no-github] [--repo-only]"
            echo "  --no-github  skip the gh calls (offline, or no gh auth)"
            echo "  --repo-only  report this repo alone, even at a workspace root"
            exit 0
            ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
done

git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository: $PWD" >&2; exit 1; }

root="$(git rev-parse --show-toplevel)"
cd "$root"

# --- helpers ---------------------------------------------------------------

# The remote's own default branch, not an assumed "main". A repo whose default is
# "master" or "trunk" would otherwise report a divergence against a ref that does
# not exist, which reads as "nothing to sync".
default_branch() {
    local ref
    ref="$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null || true)"
    if [[ -n "$ref" ]]; then
        echo "${ref#refs/remotes/origin/}"
        return
    fi
    for candidate in main master trunk; do
        if git rev-parse --verify --quiet "refs/remotes/origin/$candidate" >/dev/null; then
            echo "$candidate"
            return
        fi
    done
    echo ""
}

checkout_kind() {
    local dir
    dir="$(git rev-parse --git-dir)"
    # A worktree's .git is a file pointing into the primary repo's worktrees dir.
    [[ "$dir" == *"/.git/worktrees/"* ]] && { echo worktree; return; }
    echo "main checkout"
}

# Every count comes from one `git status --porcelain`, so they agree with the
# listing below them. Counting untracked files with `ls-files --others` instead
# reports every file inside an untracked directory, while `git status` collapses
# that directory to one line, and the two numbers then contradict each other on
# screen.
#
# Returns four numbers: staged, unstaged, untracked, and changed paths. The fourth
# is not the sum of the first three. A file that is staged and then modified again
# is `MM`, one path counted in two categories, so the sum overstates how much there
# is to look at. Anything measuring the size of the change uses the fourth.
dirty_summary() {
    local status="$1"
    printf '%s' "$status" | awk '
        NF == 0 { next }
        { paths++ }
        /^\?\?/ { untracked++; next }
        { if (substr($0,1,1) != " ") staged++; if (substr($0,2,1) != " ") unstaged++ }
        END { printf "%d %d %d %d", staged+0, unstaged+0, untracked+0, paths+0 }'
}

divergence() {
    local repo="$1" base="$2" counts
    if [[ -z "$base" ]] || ! git -C "$repo" rev-parse --verify --quiet "origin/$base" >/dev/null; then
        echo "?"
        return
    fi
    # rev-list --count --left-right gives "behind<TAB>ahead" against the base.
    counts=$(git -C "$repo" rev-list --count --left-right "origin/$base...HEAD" 2>/dev/null || echo "? ?")
    echo "$counts" | awk '{printf "%s behind, %s ahead", $1, $2}'
}

# A long backlog is orientation, not reading material. Ten lines is enough to see
# the shape of it, and the total says whether to go and look.
show_capped() {
    local label="$1" body="$2" n
    n=$(printf '%s' "$body" | grep -c . || true)
    echo "$label: $n"
    [[ "$n" -eq 0 ]] && return
    printf '%s\n' "$body" | head -10
    (( n > 10 )) && echo "  ... $((n - 10)) more"
    return 0
}

test_command() {
    if [[ -f justfile ]] && just --summary 2>/dev/null | tr ' ' '\n' | grep -qx test; then
        echo "just test"
    elif [[ -f Makefile ]] && grep -qE '^test:' Makefile; then
        echo "make test"
    elif [[ -f go.work || -f go.mod ]]; then
        echo "go test ./..."
    elif [[ -f Cargo.toml ]]; then
        echo "cargo test"
    elif [[ -f package.json ]] && grep -q '"test"' package.json; then
        echo "npm test"
    elif [[ -f pyproject.toml || -f pytest.ini ]]; then
        echo "pytest"
    else
        echo ""
    fi
}

# --- identity --------------------------------------------------------------

branch="$(git rev-parse --abbrev-ref HEAD)"
[[ "$branch" == "HEAD" ]] && branch="(detached)"
kind="$(checkout_kind)"

# Fetch before the report rather than inside it, so a failure note lands above the
# figures it applies to instead of splitting the aligned block.
git fetch --quiet --prune origin 2>/dev/null \
    || echo "NOTE: git fetch failed. Every sync figure below is from the last successful fetch."

echo "== REPO"
printf '%-12s %s\n' "name" "$(basename "$root")"
printf '%-12s %s\n' "root" "$root"
printf '%-12s %s\n' "checkout" "$kind"
printf '%-12s %s\n' "branch" "$branch"

base="$(default_branch)"
printf '%-12s %s\n' "default" "${base:-unknown}"
printf '%-12s %s\n' "vs origin" "$(divergence "$root" "$base")"

# --- working tree ----------------------------------------------------------

echo
echo "== WORKING TREE"
# Captured once, then counted and printed from the variable. Piping git into
# `head` risks SIGPIPE on a large status, and `set -o pipefail` turns that into a
# failed pipeline that kills the script.
status="$(git status --porcelain 2>/dev/null || true)"
read -r staged unstaged untracked changed <<<"$(dirty_summary "$status")"
echo "staged=$staged unstaged=$unstaged untracked=$untracked ($changed path(s))"
if (( changed > 0 )); then
    printf '%s\n' "$status" | head -20
    if (( changed > 20 )); then
        echo "... $((changed - 20)) more"
    fi
fi

echo
echo "== RECENT COMMITS"
git log --oneline --no-decorate -10

# --- nested repos ----------------------------------------------------------

nested=()
if [[ "$want_workspace" -eq 1 ]]; then
    while IFS= read -r d; do
        nested+=("$d")
    done < <(find . -mindepth 2 -maxdepth 2 -name .git -exec dirname {} \; 2>/dev/null | sed 's|^\./||' | sort)
fi

if [[ ${#nested[@]} -gt 0 ]]; then
    echo
    echo "== NESTED REPOS (${#nested[@]})"
    # Only repos holding work get a row. A workspace of many worktrees is mostly
    # quiet, and listing all of them buries the few that hold unpushed commits or
    # uncommitted changes. Nothing that needs a decision is hidden: a repo drops out
    # only when it is clean, attached, and has nothing origin does not.
    printf '%-52s %-30s %-22s %s\n' "REPO" "BRANCH" "VS ORIGIN" "DIRTY"
    quiet=0
    for d in "${nested[@]}"; do
        nb="$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
        [[ "$nb" == "HEAD" ]] && nb="(detached)"
        nbase="$(cd "$d" && default_branch)"
        div="$(divergence "$d" "$nbase")"
        nstatus="$(git -C "$d" status --porcelain 2>/dev/null || true)"
        read -r _ _ _ dirt <<<"$(dirty_summary "$nstatus")"
        ahead="$(printf '%s' "$div" | grep -oE '[0-9]+ ahead' | grep -oE '^[0-9]+' || true)"
        if [[ "$dirt" -eq 0 && "$nb" != "(detached)" && "${ahead:-0}" == "0" && "$div" != "?" ]]; then
            quiet=$((quiet + 1))
            continue
        fi
        printf '%-52s %-30s %-22s %s\n' "$d" "$nb" "$div" "$dirt"
    done
    if (( quiet > 0 )); then
        echo "($quiet more: clean, attached, nothing origin does not have)"
    fi
    echo "(figures from each repo's last fetch; this script fetches only the repo it runs in)"
fi

# --- github ----------------------------------------------------------------

echo
echo "== GITHUB"
if [[ "$want_github" -eq 0 ]]; then
    echo "skipped (--no-github)"
elif ! command -v gh >/dev/null 2>&1; then
    echo "gh is not installed."
else
    prs=$(gh pr list --state open --limit 30 \
            --json number,title,isDraft,author \
            --jq '.[] | "  #\(.number)\(if .isDraft then " [draft]" else "" end) \(.title) (\(.author.login))"' 2>&1) || prs="  (gh pr list failed: ${prs})"
    issues=$(gh issue list --state open --limit 30 \
            --json number,title \
            --jq '.[] | "  #\(.number) \(.title)"' 2>&1) || issues="  (gh issue list failed: ${issues})"
    show_capped "open PRs" "$prs"
    show_capped "open issues" "$issues"
fi

# --- tests -----------------------------------------------------------------

echo
echo "== TESTS"
cmd="$(test_command)"
if [[ -n "$cmd" ]]; then
    echo "detected: $cmd"
    echo "(this script does not run it: a suite can take minutes, and the caller"
    echo " decides whether the answer is worth the wait)"
else
    echo "no test command detected"
fi

# --- warnings --------------------------------------------------------------

echo
echo "== WARNINGS"
warned=0
if [[ "$kind" == "main checkout" ]]; then
    echo "- Main checkout. A parallel session's 'git checkout' here moves this branch"
    echo "  under you. Use a worktree for branch work."
    warned=1
fi
if [[ -n "$base" && "$branch" == "$base" ]] && (( staged + unstaged > 0 )); then
    echo "- Tracked changes sitting on $base. They need a branch before they can ship."
    warned=1
fi
behind=$(divergence "$root" "$base" | grep -oE '^[0-9]+' || true)
if [[ -n "$behind" && "$behind" != "0" ]]; then
    echo "- $behind commit(s) behind origin/$base. Anything you read here may be stale."
    warned=1
fi
# An `if` rather than `(( warned == 0 )) && echo "none"`. Under `set -e` a failing
# arithmetic test as the last statement makes the script exit 1, so the exit status
# would report "this run found warnings" as a failure, and every grounding run in a
# main checkout would look broken to a caller that checks it.
if (( warned == 0 )); then
    echo "none"
fi
