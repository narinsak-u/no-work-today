#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
[[ -d "$root" ]] || { printf 'Not a directory: %s\n' "$root" >&2; exit 1; }
root="$(cd "$root" && pwd)"
find "$root" \( -type d \( -name .git -o -name .worktrees -o -name node_modules -o -name dist -o -name build -o -name target -o -name vendor -o -name .next -o -name coverage -o -name .cache -o -name .venv -o -name venv -o -name generated \) -prune \) -o -type f \( -name 'main.*' -o -name 'index.*' -o -name 'app.py' -o -name 'server.*' -o -name 'lib.rs' \) -print | awk -v root="$root/" '
  index($0, root) == 1 {
    path = substr($0, length(root) + 1)
    depth = split(path, parts, "/")
    if (depth <= 5 && (path ~ /(^|\/)(src|app|pages|cmd|services|apps)\// || depth <= 2)) {
      if (++n <= 80) print path
    }
  }
  END { if (n > 80) printf "... %d additional candidates omitted\n", n - 80 }
'
