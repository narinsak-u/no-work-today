#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
[[ -d "$root" ]] || { printf 'Not a directory: %s\n' "$root" >&2; exit 1; }
root="$(cd "$root" && pwd -P)"
# A reported omission can be followed up one file at a time without bypassing
# the scanner's redaction, size, or per-invocation output bounds.
if [[ $# -ne 0 && $# -ne 1 && $# -ne 3 ]]; then
  printf 'Usage: find-todos.sh ROOT [RELATIVE_FILE START_LINE]\n' >&2
  exit 1
fi
start_line=1
if [[ $# -eq 3 ]]; then
  relative="$2"
  start_line="$3"
  case "/$relative/" in
    *'/../'*|*'/./'*|*'//'*) printf 'Invalid relative file\n' >&2; exit 1 ;;
  esac
  [[ "$relative" != /* && "$relative" != -* && "$relative" != *$'\n'* && "$relative" != *$'\r'* &&
     "$start_line" =~ ^[1-9][0-9]*$ && -f "$root/$relative" && ! -L "$root/$relative" ]] ||
    { printf 'Invalid scan target\n' >&2; exit 1; }
  physical_parent="$(cd "$(dirname "$root/$relative")" && pwd -P)"
  case "$physical_parent/" in
    "$root/"|"$root/"*) ;;
    *) printf 'Scan target leaves repository\n' >&2; exit 1 ;;
  esac
  case "/$relative/" in
    */.git/*|*/.worktrees/*|*/.hg/*|*/.svn/*|*/node_modules/*|*/vendor/*|*/dist/*|*/build/*|*/target/*|*/out/*|*/coverage/*|*/.next/*|*/.cache/*|*/.venv/*|*/venv/*|*/__pycache__/*|*/.tox/*|*/.turbo/*|*/.gradle/*|*/generated/*)
      printf 'Excluded scan target\n' >&2; exit 1 ;;
  esac
fi


# Candidates are evidence, not backlog items. Keep the scan bounded and never
# traverse dependency, generated, build, or version-control directories.
if [[ $# -eq 3 ]]; then
  printf '%s\0' "$root/$relative"
else
  find "$root" \( -type d \( -name .git -o -name .worktrees -o -name .hg -o -name .svn -o -name node_modules -o -name vendor -o -name dist -o -name build -o -name target -o -name out -o -name coverage -o -name .next -o -name .cache -o -name .venv -o -name venv -o -name __pycache__ -o -name .tox -o -name .turbo -o -name .gradle -o -name generated \) -prune \) -o -type f -print0
fi |
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
  LC_ALL=C awk -v path="$relative" -v start_line="$start_line" '
    # Deliberately narrow: recognizable assignments and URL password user-info,
    # not an attempt to infer arbitrary secrets from source code.
    function placeholder(value, quote) {
      if (value ~ /^["\047]/) {
        quote = substr(value, 1, 1)
        if (substr(value, length(value), 1) != quote) return 0
        value = substr(value, 2, length(value) - 2)
      }
      return value ~ /^(\[redacted( (value|password|api key|secret key|access token|token))?\]|\[hidden\]|\[masked\]|<redacted>)$/
    }
    function sensitive(source,    lower, rest, value, url, authority, info, at, offset, colon, end) {
      lower = tolower(source)
      if (lower ~ /(sk_live_|ghp_|github_pat_)[a-z0-9_-]+/) return 1
      rest = lower
      while (match(rest, /(^|[^[:alnum:]_])(([[:alnum:]_]+_)?(password|api_key|access_token|secret_key|client_secret|token)|aws_secret_access_key|authorization)[[:space:]]*[:=][[:space:]]*/)) {
        rest = substr(rest, RSTART + RLENGTH)
        if (match(rest, /^(\[[^]]+\]|"[[^]]+\]"|\047[[^]]+\047)/) || match(rest, /^[^[:space:],;#]+/)) {
          value = substr(rest, 1, RLENGTH)
          length_value = RLENGTH
          if (!placeholder(value)) return 1
          suffix = substr(rest, length_value + 1)
          if (suffix ~ /^[,;]/ &&
              suffix !~ /^[,;][[:space:]]*(([[:alnum:]_]+_)?(password|api_key|access_token|secret_key|client_secret|token)|aws_secret_access_key|authorization)[[:space:]]*[:=]/) return 1
          if (suffix !~ /^([[:space:],;#]|$)/) return 1
          rest = suffix
        }
      }
      rest = lower
      while (match(rest, /(^|[^[:alnum:]_])(postgres(ql)?|mysql|mongodb(\+srv)?|rediss?|amqps?|https?):\/\/[^[:space:]\/?#<>"\047)]+/)) {
        url = substr(rest, RSTART, RLENGTH)
        end = RSTART + RLENGTH
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
        rest = substr(rest, end)
      }
      return 0
    }
    {
      if (NR < start_line) next
      text = $0
      if (tolower(text) ~ /(^|[^[:alnum:]_])(todo|fixme|hack|xxx|wip)([^[:alnum:]_]|$)/) {
        if (sensitive(text)) {
          if (!suppressed++) first = NR
        } else if (matches < 100) {
          sub(/\r$/, "", text)
          gsub(/\t/, " ", text)
          if (length(text) > 240) text = substr(text, 1, 240) "..."
          candidates[++matches] = "C" path "\034" NR "\034" text
        } else {
          if (!omitted++) first_omitted = NR
        }
      }
    }
    END {
      for (i = 1; i <= matches; i++) print candidates[i]
      if (omitted) print "O" path "\034" first_omitted "\034" omitted
      if (suppressed) print "R" path ":" first ": [" suppressed " sensitive TODO leads suppressed]"
    }
  ' "$path"
done | awk -F "\034" '
  substr($1, 1, 1) == "C" {
    if (++safe <= 120) print substr($1, 2) ":" $2 ":" $3
    else if (safe == 121) { first_global_path = substr($1, 2); first_global_line = $2 }
    next
  }
  substr($1, 1, 1) == "O" {
    path = substr($1, 2)
    if (++notices <= 20) {
      printf "%s:%s: [%d safe TODO lead%s omitted by per-file 100 candidate limit]\n", path, $2, $3, ($3 == 1 ? "" : "s")
    } else {
      if (notices == 21) { first_quiet_path = path; first_quiet_line = $2 }
      quiet_safe += $3
    }
    next
  }
  substr($1, 1, 1) == "R" { if (++redactions <= 20) print substr($1, 2) }
  END {
    if (safe > 120)
      printf "%s:%s: [%d safe TODO lead%s omitted by global 120 candidate limit]\n", first_global_path, first_global_line, safe - 120, (safe == 121 ? "" : "s")
    if (notices > 20)
      printf "... %d additional files with %d safe TODO leads omitted; first at %s:%s\n", notices - 20, quiet_safe, first_quiet_path, first_quiet_line
    if (redactions > 20) print "... additional sensitive TODO locations suppressed"
  }
'
