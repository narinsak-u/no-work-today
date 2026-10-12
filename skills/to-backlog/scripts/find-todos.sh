#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
[[ -d "$root" ]] || { printf 'Not a directory: %s\n' "$root" >&2; exit 1; }
root="$(cd "$root" && pwd)"

# Candidates are evidence, not backlog items. Keep the scan bounded and never
# traverse dependency, generated, build, or version-control directories.
find "$root" \( -type d \( -name .git -o -name .hg -o -name .svn -o -name node_modules -o -name vendor -o -name dist -o -name build -o -name target -o -name out -o -name coverage -o -name .next -o -name .cache -o -name .venv -o -name venv -o -name __pycache__ -o -name .tox -o -name .turbo -o -name .gradle -o -name generated \) -prune \) -o -type f -print0 |
while IFS= read -r -d '' path; do
  relative="${path#"$root"/}"
  case "$relative" in
    docs/backlog.md|*.lock|*.min.js|*.map|*.png|*.jpg|*.jpeg|*.gif|*.pdf|*.zip|*.gz|*.jar|*.class|*.wasm|*.exe|*.o|*.a|*.so|*.dylib|*.sqlite|*.db) continue ;;
  esac
  # Avoid scanning huge files even if they have a source-like extension.
  [[ "$(wc -c < "$path")" -le 524288 ]] || continue
  LC_ALL=C awk -v path="$relative" '
    index($0, sprintf("%c", 0)) { binary = 1; exit }
    {
      text = $0
      if (tolower(text) ~ /(^|[^[:alnum:]_])(todo|fixme|hack|xxx|wip)([^[:alnum:]_]|$)/ && matches < 100) {
        sub(/\r$/, "", text)
        gsub(/\t/, " ", text)
        if (length(text) > 240) text = substr(text, 1, 240) "..."
        candidates[++matches] = path ":" NR ":" text
      }
    }
    END { if (!binary) for (i = 1; i <= matches; i++) print candidates[i] }
  ' "$path"
done | awk 'NR <= 120 { print } END { if (NR > 120) printf "... %d additional candidates omitted; narrow the scan before interpreting\n", NR - 120 }'
