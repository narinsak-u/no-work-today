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
    # Deliberately narrow: recognizable assignments and URL password user-info,
    # not an attempt to infer arbitrary secrets from source code.
    function placeholder(value) {
      return value ~ /^(\[redacted( (value|password|api key|secret key|access token|token))?\]|\[hidden\]|\[masked\]|<redacted>)$/
    }
    function sensitive(source,    lower, rest, value, url, authority, info, at, offset, colon) {
      lower = tolower(source)
      if (lower ~ /(sk_live_|ghp_|github_pat_)[a-z0-9_-]+/) return 1
      rest = lower
      while (match(rest, /(^|[^[:alnum:]_])(([[:alnum:]_]+_)?(password|api_key|access_token|secret_key|token)|aws_secret_access_key|authorization)[[:space:]]*[:=][[:space:]]*/)) {
        rest = substr(rest, RSTART + RLENGTH)
        if (match(rest, /^\[[^]]+\]/) || match(rest, /^[^[:space:],;#]+/)) {
          value = substr(rest, 1, RLENGTH)
          if (!placeholder(value)) return 1
          if (value ~ /^\[/ && (substr(rest, RLENGTH + 1, 1) ~ /[^[:space:],;#]/ || substr(rest, RLENGTH + 1, 2) ~ /^,[^[:space:],;#]/)) return 1
          rest = substr(rest, RLENGTH + 1)
        }
      }
      rest = lower
      while (match(rest, /(^|[^[:alnum:]_])(postgres(ql)?|mysql|mongodb(\+srv)?|rediss?|amqps?|https?):\/\/[^[:space:]\/?#<>"\047)]+/)) {
        url = substr(rest, RSTART, RLENGTH)
        authority = url
        sub(/^.*:\/\//, "", authority)
        info = authority
        at = 0
        offset = 0
        while (match(info, /@|%40/)) {
          at = offset + RSTART
          offset += RSTART + RLENGTH - 1
          info = substr(info, RSTART + RLENGTH)
        }
        if (at) {
          info = substr(authority, 1, at - 1)
          colon = match(info, /:|%3a/)
          if (colon) {
            value = substr(info, colon + RLENGTH)
            if (value != "" && !placeholder(value)) return 1
          }
        }
        rest = substr(rest, RSTART + RLENGTH)
      }
      return 0
    }
    {
      text = $0
      if (tolower(text) ~ /(^|[^[:alnum:]_])(todo|fixme|hack|xxx|wip)([^[:alnum:]_]|$)/) {
        if (sensitive(text)) {
          if (!suppressed++) first = NR
        } else if (matches < 100) {
          sub(/\r$/, "", text)
          gsub(/\t/, " ", text)
          if (length(text) > 240) text = substr(text, 1, 240) "..."
          candidates[++matches] = path ":" NR ":" text
        }
      }
    }
    END {
      for (i = 1; i <= matches; i++) print "C" candidates[i]
      if (suppressed) print "R" path ":" first ": [" suppressed " sensitive TODO leads suppressed]"
    }
  ' "$path"
done | awk '
  substr($0, 1, 1) == "C" { if (++safe <= 120) print substr($0, 2); next }
  substr($0, 1, 1) == "R" { if (++redactions <= 20) print substr($0, 2) }
  END {
    if (safe > 120) printf "... %d additional candidates omitted; narrow the scan before interpreting\n", safe - 120
    if (redactions > 20) print "... additional sensitive TODO locations suppressed"
  }
'
