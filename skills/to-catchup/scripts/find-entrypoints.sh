#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
[[ -d "$root" ]] || { printf 'Not a directory: %s\n' "$root" >&2; exit 1; }
root="$(cd "$root" && pwd)"
find "$root" \( -type d \( -name .git -o -name .worktrees -o -name node_modules -o -name dist -o -name build -o -name target -o -name vendor -o -name .next -o -name coverage -o -name .cache -o -name .venv -o -name venv -o -name generated \) -prune \) -o -type f \( -name 'main.*' -o -name 'index.*' -o -name 'app.py' -o -name 'server.*' -o -name 'lib.rs' -o -name 'page.*' -o -name 'layout.*' \) -print | awk -v root="$root/" '
  index($0, root) == 1 {
    path = substr($0, length(root) + 1)
    depth = split(path, parts, "/")
    is_router = (parts[1] == "app" || (parts[1] == "src" && parts[2] == "app")) &&
                parts[depth] ~ /^(page|layout)\.(js|jsx|ts|tsx)$/
    if (is_router) {
      first_route_segment = (parts[1] == "app" ? 2 : 3)
      for (segment = first_route_segment; segment < depth; segment++) {
        if (parts[segment] ~ /^_/) {
          is_router = 0
          break
        }
      }
    }
    is_existing = (path ~ /(^|\/)(src|app|pages|cmd|services|apps)\// || depth <= 2) &&
                  path !~ /(^|\/)(page|layout)\.[^\/]+$/
    if (is_router || (depth <= 5 && is_existing)) {
      if (++n <= 80) print path
    }
  }
  END { if (n > 80) printf "... %d additional candidates omitted\n", n - 80 }
'
