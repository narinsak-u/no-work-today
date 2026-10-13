#!/usr/bin/env bash
set -euo pipefail

file="${1:-docs/overview.md}"
[[ -s "$file" ]] || { printf 'Overview missing or empty: %s\n' "$file" >&2; exit 1; }
for heading in '# Project Overview' '## Purpose' '## Project Tree' '## Workflow' '## Scripts' '## Important Notes'; do
  if ! grep -Fxq "$heading" "$file"; then
    printf 'Overview missing section: %s\n' "$heading" >&2
    exit 1
  fi
done
if grep -Eiq -- '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|(sk_live_|ghp_|github_pat_)[A-Za-z0-9_-]{8,}' "$file" ||
  LC_ALL=C awk '
    function placeholder(value, quote) {
      if (value ~ /^["\047]/) {
        quote = substr(value, 1, 1)
        if (substr(value, length(value), 1) != quote) return 0
        value = substr(value, 2, length(value) - 2)
      }
      return value ~ /^\[(REDACTED|PLACEHOLDER|EXAMPLE|SAMPLE|DUMMY|YOUR)([ _-]+[[:alnum:]_ -]+)?\]$/ ||
        value ~ /^<(REDACTED|PLACEHOLDER|EXAMPLE|SAMPLE|DUMMY|YOUR)([ _-]+[[:alnum:]_ -]+)?>$/
    }
    {
      line = toupper($0)
      rest = line
      while (match(rest, /(^|[^[:alnum:]_])([[:alnum:]_]*_)?(PASSWORD|API_KEY|ACCESS_TOKEN|SECRET_KEY|TOKEN|AWS_SECRET_ACCESS_KEY)[[:space:]]*[:=][[:space:]]*/)) {
        rest = substr(rest, RSTART + RLENGTH)
        if (match(rest, /^(\[[^]]+\]|<[^>]+>)/)) {
          value = substr(rest, RSTART, RLENGTH)
          suffix = substr(rest, RLENGTH + 1)
          if (suffix ~ /^[,;]/ &&
              suffix !~ /^[,;][[:space:]]*([[:alnum:]_]*_)?(PASSWORD|API_KEY|ACCESS_TOKEN|SECRET_KEY|TOKEN|AWS_SECRET_ACCESS_KEY)[[:space:]]*[:=]/)
            bad = 1
          if (suffix !~ /^([[:space:],;]|$)/) value = value suffix
        } else if (match(rest, /^[^[:space:];]+/)) {
          value = substr(rest, RSTART, RLENGTH)
        } else {
          value = ""
        }
        if (value != "" && !placeholder(value)) bad = 1
      }
      rest = line
      while (match(rest, /(POSTGRES(QL)?|MYSQL|MONGODB(\+SRV)?|REDIS(S)?|AMQP(S)?|HTTPS?):\/\//)) {
        rest = substr(rest, RSTART + RLENGTH)
        if (match(rest, /^[^\/@[:space:]]+(:|%3A)([^\/@[:space:]]|\[[^]]+\])+(@|%40)/)) {
          userinfo = substr(rest, RSTART, RLENGTH)
          sub(/(@|%40)$/, "", userinfo)
          match(userinfo, /(:|%3A)/)
          password = substr(userinfo, RSTART + RLENGTH)
          if (!placeholder(password)) bad = 1
        }
      }
    }
    END { exit !bad }
  ' "$file"; then
  printf 'Overview contains a possible secret; remove its value before sharing\n' >&2
  exit 1
fi

# A fingerprint is optional for clean legacy overviews. When present, validate
# it without modifying any submitted bytes.
fingerprints="$(LC_ALL=C awk '
  /^output_sha256:/ {
    count++
    sub(/\r$/, "")
    if ($0 !~ /^output_sha256: [0-9a-f]+$/ || length($0) != 79) bad = 1
    else expected = substr($0, 16)
  }
  END { if (bad || count > 1) exit 1; if (count) print expected }
' "$file")" || {
  printf 'Overview has an invalid output_sha256 fingerprint\n' >&2
  exit 1
}
if [[ -n "$fingerprints" ]]; then
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(LC_ALL=C sed '/^output_sha256: /d' "$file" | sha256sum)"
    actual="${actual%% *}"
  elif command -v shasum >/dev/null 2>&1; then
    actual="$(LC_ALL=C sed '/^output_sha256: /d' "$file" | shasum -a 256)"
    actual="${actual%% *}"
  elif command -v openssl >/dev/null 2>&1; then
    actual="$(LC_ALL=C sed '/^output_sha256: /d' "$file" | openssl dgst -sha256)"
    actual="${actual##* }"
  else
    printf 'Overview: SHA-256 utility unavailable (sha256sum, shasum, or openssl required)\n' >&2
    exit 1
  fi
  [[ "$actual" == "$fingerprints" ]] || {
    printf 'Overview fingerprint mismatch; preserve user edits\n' >&2
    exit 1
  }
fi
