#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
[[ -d "$root" ]] || { printf 'Not a directory: %s\n' "$root" >&2; exit 1; }
root="$(cd "$root" && pwd)"

# Candidates are evidence, not backlog items. Keep the scan bounded and never
# traverse dependency, generated, build, or version-control directories.
find "$root" \( -type d \( -name .git -o -name .worktrees -o -name .hg -o -name .svn -o -name node_modules -o -name vendor -o -name dist -o -name build -o -name target -o -name out -o -name coverage -o -name .next -o -name .cache -o -name .venv -o -name venv -o -name __pycache__ -o -name .tox -o -name .turbo -o -name .gradle -o -name generated \) -prune \) -o -type f -print0 |
while IFS= read -r -d '' path; do
  relative="${path#"$root"/}"
  case "$relative" in
    docs/backlog.md|.env|.env.*|*/.env|*/.env.*|*credentials*|*secrets*|*.pem|*.key|*.lock|*.min.js|*.map|*.png|*.jpg|*.jpeg|*.gif|*.pdf|*.zip|*.gz|*.jar|*.class|*.wasm|*.exe|*.o|*.a|*.so|*.dylib|*.sqlite|*.db) continue ;;
  esac
  # Avoid scanning huge files even if they have a source-like extension.
  [[ "$(wc -c < "$path")" -le 524288 ]] || continue
  # Bash read -d '' stops at a NUL byte; unlike awk, this works with BSD awk
  # where a NUL-format probe can behave like an empty-string match.
  if IFS= read -r -d '' _ < "$path"; then continue; fi
  LC_ALL=C awk -v path="$relative" '
    {
      text = $0
      if (tolower(text) ~ /(^|[^[:alnum:]_])(todo|fixme|hack|xxx|wip)([^[:alnum:]_]|$)/ && matches < 100 &&
          tolower(text) !~ /(^|[^[:alnum:]_])(password|api_?key|secret_?key|access_?token|github_token|aws_secret_access_key|authorization)[[:space:]]*[:=][[:space:]]*[^[:space:]<]+/ &&
          tolower(text) !~ /(sk_live_|ghp_|github_pat_)[a-z0-9_-]+/) {
        sub(/\r$/, "", text)
        gsub(/\t/, " ", text)
        if (length(text) > 240) text = substr(text, 1, 240) "..."
        candidates[++matches] = path ":" NR ":" text
      }
    }
    END { for (i = 1; i <= matches; i++) print candidates[i] }
  ' "$path"
done | awk 'NR <= 120 { print } END { if (NR > 120) printf "... %d additional candidates omitted; narrow the scan before interpreting\n", NR - 120 }'
