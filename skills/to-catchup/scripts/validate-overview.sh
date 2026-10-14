#!/usr/bin/env bash
set -euo pipefail

file="${1:-docs/overview.md}"
[[ -s "$file" ]] || { printf 'Overview missing or empty: %s\n' "$file" >&2; exit 1; }
<<<<<<< HEAD
expected_headings=(
  '# Project Overview'
  '## 1. Purpose'
  '## 2. Tech Stack'
  '## 3. Architecture'
  '## 4. Main Flows'
  '## 5. Core Modules'
  '## 6. Important Files'
  '## 7. Data & External Services'
  '## 8. Development Workflow'
  '## 9. Start Here'
  '## 10. Important Notes'
)
mapfile -t actual_headings < <(grep -E '^#{1,2} ' "$file" || true)
headings_match=1
if [[ "${#actual_headings[@]}" -ne "${#expected_headings[@]}" ]]; then
  headings_match=0
else
  for i in "${!expected_headings[@]}"; do
    [[ "${actual_headings[$i]}" == "${expected_headings[$i]}" ]] || headings_match=0
  done
fi
if [[ "$headings_match" -ne 1 ]]; then
  printf 'Overview must contain exactly the required major sections in order\n' >&2
  exit 1
fi
=======
for heading in '# Project Overview' '## Purpose' '## Tech Stack' '## Project Tree' '## Workflow' '## Scripts' '## Important Notes'; do
  if ! grep -Fxq "$heading" "$file"; then
    printf 'Overview missing section: %s\n' "$heading" >&2
    exit 1
  fi
done
>>>>>>> d910d8d (feat: improve catchup overview inventories)
if grep -Eiq -- '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|(sk_live_|ghp_|github_pat_)[A-Za-z0-9_-]{8,}' "$file" ||
  LC_ALL=C awk '
    function placeholder(value, quote) {
      if (value ~ /^["\047]/) {
        quote = substr(value, 1, 1)
        if (substr(value, length(value), 1) != quote) return 0
        value = substr(value, 2, length(value) - 2)
      }
      sub(/[.?!]+$/, "", value)
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

# A fingerprint is optional for clean legacy overviews. When present, it must
# occur once in the exact terminal skill-state block shown in the skill guide.
fingerprints="$(LC_ALL=C awk '
  {
    previous_two = previous_one
    previous_one = last
    last = $0
  }
  /^[[:space:]]*output_sha256([[:space:]]|:|$)/ { count++; field_line = NR; field = $0 }
  /^<!-- skill-state$/ { openings++ }
  END {
    if (count == 0) exit 0
    if (count != 1 || openings != 1 || field_line != NR - 1 ||
        previous_two != "<!-- skill-state" || previous_one != field || last != "-->") exit 1
    if (field !~ /^output_sha256: [0-9a-f]+$/ || length(field) != 79) exit 1
    print substr(field, 16)
  }
' "$file")" || {
  printf 'Overview has an invalid output_sha256 fingerprint\n' >&2
  exit 1
}
if [[ -n "$fingerprints" ]]; then
  fingerprint_file="$(mktemp "${TMPDIR:-/tmp}/overview-fingerprint.XXXXXX")"
  trap 'rm -f -- "$fingerprint_file"' EXIT
  while :; do
    line=
    if IFS= read -r line; then terminated=1; else terminated=0; fi
    [[ $terminated == 1 || -n $line ]] || break
    if [[ "$line" != output_sha256:* ]]; then
      printf '%s' "$line" >> "$fingerprint_file"
      [[ $terminated == 0 ]] || printf '\n' >> "$fingerprint_file"
    fi
  done < "$file"
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$fingerprint_file")"
    actual="${actual%% *}"
  elif command -v shasum >/dev/null 2>&1; then
    actual="$(shasum -a 256 "$fingerprint_file")"
    actual="${actual%% *}"
  elif command -v openssl >/dev/null 2>&1; then
    actual="$(openssl dgst -sha256 "$fingerprint_file")"
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
