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
