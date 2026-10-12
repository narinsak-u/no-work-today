#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
[[ -d "$root" ]] || { printf 'Not a directory: %s\n' "$root" >&2; exit 1; }
root="$(cd "$root" && pwd)"
printf 'REPO_ROOT=%s\n' "$root"
if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'BRANCH=%s\n' "$(git -C "$root" symbolic-ref --quiet --short HEAD 2>/dev/null || printf 'detached')"
fi
printf 'INVENTORY (top-level and selected paths, at most 120):\n'
find "$root" \( -type d \( -name .git -o -name .worktrees -o -name node_modules -o -name dist -o -name build -o -name target -o -name vendor -o -name .next -o -name coverage -o -name .cache -o -name .venv -o -name venv -o -name generated \) -prune \) -o \( -type d -o -type f \) -print | awk -v root="$root/" '
  index($0, root) == 1 {
    path = substr($0, length(root) + 1)
    depth = split(path, parts, "/")
    if (depth <= 2 || (depth <= 4 && (path ~ /(^|\/)(README[^\/]*|AGENTS\.md|package\.json|Cargo\.toml|go\.mod|pyproject\.toml|Dockerfile|compose[^\/]*|\.env\.example|[^\/]+\.ya?ml)$/ || path ~ /(^|\/)(src|apps|packages|services|tests|docs|\.github)\//))) {
      if (++n <= 120) print path
    }
  }
  END { if (n > 120) printf "... %d additional selected paths omitted; inspect a specific module next\n", n - 120 }
'
