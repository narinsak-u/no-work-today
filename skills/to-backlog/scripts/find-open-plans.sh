#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo 'usage: find-open-plans.sh ROOT' >&2
  exit 2
fi
root=$1
if [[ ! -d "$root" ]]; then
  echo "repository root is not a directory: $root" >&2
  exit 2
fi

result=$(mktemp "${TMPDIR:-/tmp}/to-backlog-plans.XXXXXX")
trap 'rm -f "$result"' EXIT

scan_root() {
  local directory=$1
  [[ -d "$directory" ]] || return 0
  find "$directory" -type f \( -iname '*.md' -o -iname '*.markdown' \) -print0 |
    while IFS= read -r -d '' file; do
      local unchecked=0 done_status=0 candidate=0
      if grep -Eq '^[[:space:]]*(-|\*)[[:space:]]+\[[[:space:]]\]' "$file"; then
        unchecked=1
      fi
      if grep -Eiq '^[[:space:]]*Status:[[:space:]]*Done[[:space:]]*$' "$file"; then
        done_status=1
      fi
      if (( unchecked )); then
        candidate=1
      elif (( done_status )); then
        candidate=0
      elif grep -Eiq '^[[:space:]]*Status:' "$file"; then
        candidate=1
      fi
      if (( candidate )); then
        relative=${file#"$root"/}
        printf 'PLAN_FILE=%q\n' "$relative" >> "$result"
      fi
    done
}

scan_root "$root/docs/plans"
scan_root "$root/docs/specs"
if [[ -d "$root/.scratch" ]]; then
  find "$root/.scratch" -type d -name issues -print0 |
    while IFS= read -r -d '' directory; do scan_root "$directory"; done
fi
LC_ALL=C sort -o "$result" "$result"
cat "$result"
