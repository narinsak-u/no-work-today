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
if grep -Eiq -- '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|(^|[^[:alnum:]_])(API_KEY|SECRET_KEY|ACCESS_TOKEN|GITHUB_TOKEN|AWS_SECRET_ACCESS_KEY|PASSWORD|TOKEN)[[:space:]]*[:=][[:space:]]*[^[:space:]<]{6,}|(sk_live_|ghp_|github_pat_)[A-Za-z0-9_-]{8,}' "$file"; then
  printf 'Overview contains a possible secret; remove the value before sharing\n' >&2
  exit 1
fi
