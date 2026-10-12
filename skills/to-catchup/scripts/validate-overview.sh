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
if grep -Eq -- '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|(^|[[:space:]])(API_KEY|SECRET_KEY|ACCESS_TOKEN|PASSWORD)[[:space:]]*[:=][[:space:]]*[^[:space:]<]{6,}' "$file"; then
  printf 'Overview contains a possible secret; remove the value before sharing\n' >&2
  exit 1
fi
