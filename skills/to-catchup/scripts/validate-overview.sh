#!/usr/bin/env bash
set -euo pipefail

file="${1:-docs/overview.md}"
[[ -s "$file" ]] || { printf 'Overview missing or empty: %s\n' "$file" >&2; exit 1; }
for heading in '# Project Overview' '## Purpose' '## Stack' '## Architecture' '## Application Flow' '## Important Modules' '## Important Files' '## Data Flow' '## External Dependencies' '## Environment and Configuration' '## Development Workflow' '## Recommended Reading Order' '## Cautions'; do
  if ! grep -Fxq "$heading" "$file"; then
    printf 'Overview missing section: %s\n' "$heading" >&2
    exit 1
  fi
done
if grep -Eiq -- '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|(sk_live_|ghp_|github_pat_)[A-Za-z0-9_-]{8,}' "$file" ||
  LC_ALL=C awk '
    function placeholder(value) {
      if (value ~ /^["\047]/) value = substr(value, 2, length(value) - 2)
      return value ~ /^\[(REDACTED|PLACEHOLDER|EXAMPLE|SAMPLE|DUMMY|YOUR)([ _-]+[[:alnum:]_ -]+)?\]$/ ||
        value ~ /^<(REDACTED|PLACEHOLDER|EXAMPLE|SAMPLE|DUMMY|YOUR)([ _-]+[[:alnum:]_ -]+)?>$/
    }
    {
      line = toupper($0)
      rest = line
      while (match(rest, /(^|[^[:alnum:]_])([[:alnum:]_]*_)?(PASSWORD|API_KEY|ACCESS_TOKEN|SECRET_KEY|TOKEN|AWS_SECRET_ACCESS_KEY)[[:space:]]*[:=][[:space:]]*/)) {
        rest = substr(rest, RSTART + RLENGTH)
        if ((match(rest, /^\[[^]]+\]/) || match(rest, /^<[^>]+>/) || match(rest, /^[^[:space:],;]+/)) &&
            !placeholder(substr(rest, RSTART, RLENGTH))) bad = 1
      }
      rest = line
      while (match(rest, /(POSTGRES(QL)?|MYSQL|MONGODB(\+SRV)?|REDIS(S)?|AMQP(S)?|HTTPS?):\/\//)) {
        rest = substr(rest, RSTART + RLENGTH)
        if (match(rest, /^[^\/@[:space:]]+(:|%3A)([^\/@[:space:]]+|\[[^]]+\])(@|%40)/)) {
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
  printf 'Overview contains a possible secret; remove the value before sharing\n' >&2
  exit 1
fi
