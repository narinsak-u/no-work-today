#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
[[ -d "$root" ]] || { printf 'Not a directory: %s\n' "$root" >&2; exit 1; }
root="$(cd "$root" && pwd)"
printf 'REPO_ROOT=%s\n' "$root"
if ! git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'GIT=none\n'
  exit 0
fi
printf 'GIT=worktree\n'
printf 'BRANCH=%s\n' "$(git -C "$root" symbolic-ref --quiet --short HEAD 2>/dev/null || printf 'detached')"
printf 'HEAD=%s\n' "$(git -C "$root" rev-parse --verify HEAD 2>/dev/null || printf 'none')"
printf 'WORKING_TREE_STATUS (index/worktree codes, at most 80 paths):\n'
# --no-optional-locks prevents Git status from refreshing the target index.
git --no-optional-locks -C "$root" -c core.quotePath=false status --short --untracked-files=normal |
  awk 'NR <= 80 { printf "STATUS=%s %s\n", substr($0, 1, 2), substr($0, 4) }
       END { if (NR > 80) printf "... %d additional changed paths omitted\n", NR - 80 }'

# File lists and diffstat are leads, not evidence of completed work. Avoid
# external diff drivers and textconv; summarize only metadata, never file contents.
show_diff() {
  local label="$1" stage="$2"
  local -a options=()
  if [[ "$stage" == staged ]]; then options=(--cached); fi
  printf '%s_CHANGED_FILES (at most 40 paths):\n' "$label"
  git --no-optional-locks -C "$root" -c core.quotePath=true diff --no-ext-diff --no-textconv "${options[@]}" --name-status -- |
    awk -v stage="$stage" 'NR <= 40 { print "CHANGE=" $0 }
      END { if (NR > 40) printf "... %d additional %s changed files omitted\n", NR - 40, stage }'
  printf '%s_DIFF_STAT (at most 40 files; no file contents):\n' "$label"
  git --no-optional-locks -C "$root" -c core.quotePath=true diff --no-ext-diff --no-textconv "${options[@]}" --stat --stat-count=40 --stat-width=120 --
}
show_diff STAGED staged
show_diff UNSTAGED unstaged
