#!/usr/bin/env bash
set -euo pipefail

skill="$(cd "$(dirname "$0")/../skills/to-backlog" && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/backlog skill tests.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
root="$fixture/my project"
mkdir -p "$root/src" "$root/vendor" "$root/node_modules" "$root/dist" "$root/generated" "$root/docs"
printf '// TODO: Add retries to failed payment capture\n' > "$root/src/payments.go"
printf '// FIXME: Preserve order during replay\n' > "$root/src/order file.go"
printf 'WIP: document migration blockers\n' > "$root/notes.txt"
printf 'TODO: vendored task\n' > "$root/vendor/dependency.go"
printf 'TODO: dependency task\n' > "$root/node_modules/library.js"
printf 'TODO: built task\n' > "$root/dist/output.js"
printf 'TODO: generated task\n' > "$root/generated/schema.go"
printf 'TODO: fake embedded binary\000more data\n' > "$root/src/binary.dat"
printf 'TODO: skip generated backlog\n' > "$root/docs/backlog.md"
printf 'API_KEY=live-secret # TODO rotate\n' > "$root/.env"
printf 'password=live-secret # TODO rotate\n' > "$root/src/config.yml"
printf '// TODO: rotate DB_PASSWORD=top-secret-credential\n' > "$root/src/credential.go"
printf '// FIXME: remove mysql://service:connection-secret@db.example.test/tasks\n' > "$root/src/database.go"
printf '%s\n' '// TODO: remove postgresql://service%3Aconnection-secret%40db.example.test/tasks' > "$root/src/encoded-url.go"
printf '// TODO: rotate CI_ACCESS_TOKEN: top-secret-credential\n' > "$root/src/access-token.go"
printf '// TODO: update DB_PASSWORD name in documentation\n' > "$root/src/config-names.go"
printf '// TODO: use DB_PASSWORD=[REDACTED] in examples\n' > "$root/src/placeholder.go"
printf '// TODO: rotate sk_live_12345678x\n' > "$root/src/stripe-token.go"
printf '// FIXME: replace ghp_12345678x\n' > "$root/src/github-token.go"
printf '// TODO: revoke github_pat_12345678x\n' > "$root/src/github-pat.go"
printf '// TODO: document DB_PASSWORD=[REDACTED VALUE]\n' > "$root/src/redacted-value.go"
printf '// TODO: rotate DB_PASSWORD=[REDACTED VALUE]still-secret\n' > "$root/src/redaction-suffix.go"
printf '// TODO: rotate DB_PASSWORD=[REDACTED VALUE],production-secret\n' > "$root/src/redaction-comma.go"
printf '// TODO: rotate DB_PASSWORD=[REDACTED], fixture_credential\n' > "$root/src/redaction-comma-space.go"
printf '// TODO: rotate DB_PASSWORD=[REDACTED];actual-secret\n' > "$root/src/redaction-semicolon.go"
printf '// TODO: use DB_PASSWORD="[REDACTED]" in examples\n' > "$root/src/quoted-placeholder.go"
printf '// TODO: rotate client_secret = live-client-credential\n' > "$root/src/client-secret.go"
printf '// TODO: rotate OAUTH_CLIENT_SECRET: "quoted-client-credential"\n' > "$root/src/oauth-client-secret.go"
printf '// TODO: document client_secret=[REDACTED] in examples\n' > "$root/src/client-placeholder.go"
printf '// TODO: use OAUTH_CLIENT_SECRET="<redacted>" in examples\n' > "$root/src/quoted-client-placeholder.go"
cp "$root/src/credential.go" "$fixture/credential-before"
cp "$root/src/database.go" "$fixture/database-before"

candidates="$(bash "$skill/scripts/find-todos.sh" "$root")"
[[ "$candidates" == *'src/payments.go:1:'*'Add retries'* ]] || exit 1
[[ "$candidates" == *'src/order file.go:1:'*'Preserve order'* ]] || exit 1
[[ "$candidates" == *'notes.txt:1:'*'migration blockers'* ]] || exit 1
[[ "$candidates" != *'vendor/'* && "$candidates" != *'node_modules/'* && "$candidates" != *'dist/'* && "$candidates" != *'generated/'* && "$candidates" != *'binary.dat'* && "$candidates" != *'docs/backlog.md'* && "$candidates" != *'live-secret'* ]] || exit 1
[[ "$candidates" == *'src/credential.go:1:'*'sensitive TODO'* && "$candidates" == *'src/database.go:1:'*'sensitive TODO'* && "$candidates" == *'src/encoded-url.go:1:'*'sensitive TODO'* && "$candidates" == *'src/access-token.go:1:'*'sensitive TODO'* ]] || exit 1
for file in stripe-token.go github-token.go github-pat.go; do
  [[ "$candidates" == *"src/$file:1:"*'sensitive TODO'* ]] || exit 1
done
[[ "$candidates" == *'src/redaction-suffix.go:1:'*'sensitive TODO'* ]] || exit 1
[[ "$candidates" == *'src/redaction-comma.go:1:'*'sensitive TODO'* ]] || exit 1
for file in redaction-comma-space.go redaction-semicolon.go; do
  [[ "$candidates" == *"src/$file:1:"*'sensitive TODO'* ]] || exit 1
done
[[ "$candidates" == *'src/quoted-placeholder.go:1:'*'DB_PASSWORD="[REDACTED]"'* ]] || exit 1
[[ "$candidates" == *'src/config-names.go:1:'*'DB_PASSWORD name'* && "$candidates" == *'src/placeholder.go:1:'*'[REDACTED]'* && "$candidates" == *'src/redacted-value.go:1:'*'[REDACTED VALUE]'* ]] || exit 1
for file in client-secret.go oauth-client-secret.go; do
  [[ "$candidates" == *"src/$file:1:"*'sensitive TODO'* ]] || exit 1
done
[[ "$candidates" == *'src/client-placeholder.go:1:'*'client_secret=[REDACTED]'* ]] || exit 1
[[ "$candidates" == *'src/quoted-client-placeholder.go:1:'*'OAUTH_CLIENT_SECRET="<redacted>"'* ]] || exit 1
[[ "$candidates" != *'top-secret-credential'* && "$candidates" != *'connection-secret'* && "$candidates" != *'mysql://'* && "$candidates" != *'sk_live_12345678x'* && "$candidates" != *'ghp_12345678x'* && "$candidates" != *'github_pat_12345678x'* && "$candidates" != *'still-secret'* && "$candidates" != *'production-secret'* && "$candidates" != *'fixture_credential'* && "$candidates" != *'actual-secret'* ]] || exit 1
[[ "$candidates" != *'live-client-credential'* && "$candidates" != *'quoted-client-credential'* ]] || exit 1
cmp -s "$fixture/credential-before" "$root/src/credential.go"
cmp -s "$fixture/database-before" "$root/src/database.go"
mkdir -p "$fixture/standalone"
cp -R "$skill" "$fixture/standalone/to-backlog"
standalone="$(bash "$fixture/standalone/to-backlog/scripts/find-todos.sh" "$root")"
[[ "$standalone" == *'src/credential.go:1:'*'sensitive TODO'* && "$standalone" == *'src/payments.go:1:'*'Add retries'* && "$standalone" == *'src/github-pat.go:1:'*'sensitive TODO'* ]] || exit 1
[[ "$standalone" != *'top-secret-credential'* && "$standalone" != *'sk_live_12345678x'* && "$standalone" != *'ghp_12345678x'* && "$standalone" != *'github_pat_12345678x'* ]] || exit 1
[[ "$standalone" == *'src/client-secret.go:1:'*'sensitive TODO'* && "$standalone" == *'src/oauth-client-secret.go:1:'*'sensitive TODO'* ]] || exit 1
[[ "$standalone" != *'live-client-credential'* && "$standalone" != *'quoted-client-credential'* ]] || exit 1

# Suppressed candidates must not occupy the per-file safe-lead allowance.
mkdir -p "$fixture/budget"
printf 'TODO: ACCESS_TOKEN=top-secret-credential\n' > "$fixture/budget/leads.txt"
for number in {1..100}; do printf 'FIXME: safe lead %d\n' "$number" >> "$fixture/budget/leads.txt"; done
budget="$(bash "$skill/scripts/find-todos.sh" "$fixture/budget")"
[[ "$budget" == *'leads.txt:1:'*'sensitive TODO'* && "$budget" == *'leads.txt:101:FIXME: safe lead 100'* ]] || exit 1
[[ "$budget" != *'top-secret-credential'* ]] || exit 1
# A suppressed lead also leaves the global safe-lead allowance intact.
for number in {101..120}; do printf 'FIXME: safe lead %d\n' "$number" >> "$fixture/budget/extra.txt"; done
global="$(bash "$skill/scripts/find-todos.sh" "$fixture/budget")"
[[ "$global" == *'extra.txt:20:FIXME: safe lead 120'* && "$global" != *'additional candidates omitted'* ]] || exit 1

# Per-file safe omissions are distinct from sensitive suppression and name
# the first hidden line, even when the path contains spaces.
mkdir -p "$fixture/limits/src with spaces"
printf 'TODO: API_KEY=never-print-this-value\n' > "$fixture/limits/src with spaces/leads file.txt"
printf 'TODO: use https://example.test/tasks\n' >> "$fixture/limits/src with spaces/leads file.txt"
for number in {1..100}; do printf 'FIXME: safe lead %d\n' "$number" >> "$fixture/limits/src with spaces/leads file.txt"; done
limited="$(bash "$skill/scripts/find-todos.sh" "$fixture/limits")"
[[ "$limited" == *'src with spaces/leads file.txt:1:'*'sensitive TODO'* ]] || exit 1
[[ "$limited" == *'src with spaces/leads file.txt:2:TODO: use https://example.test/tasks'* ]] || exit 1
[[ "$limited" == *'src with spaces/leads file.txt:101:FIXME: safe lead 99'* ]] || exit 1
[[ "$limited" == *'src with spaces/leads file.txt:102:'*'1 safe TODO lead omitted'* ]] || exit 1
[[ "$limited" != *'src with spaces/leads file.txt:102:FIXME: safe lead 100'* && "$limited" != *'never-print-this-value'* ]] || exit 1
# The existing 120 global cap excludes one safe match regardless of whether
# find visits the spaced directory or the global file first.
for number in {1..21}; do printf 'TODO: global lead %d\n' "$number" >> "$fixture/limits/zz global file.txt"; done
overflow="$(bash "$skill/scripts/find-todos.sh" "$fixture/limits")"
[[ "$(printf '%s\n' "$overflow" | grep -Ec ':[0-9]+:(TODO|FIXME):')" -eq 120 ]] || exit 1
[[ "$(printf '%s\n' "$overflow" | grep -c 'omitted by global 120 candidate limit')" -eq 1 ]] || exit 1
[[ "$overflow" == *'zz global file.txt:20:TODO: global lead 20'* ]] || exit 1
if [[ "$overflow" == *'zz global file.txt:21:TODO: global lead 21'* ]]; then
  [[ "$overflow" == *'src with spaces/leads file.txt:101: [1 safe TODO lead omitted by global 120 candidate limit]'* ]] || exit 1
  [[ "$overflow" != *'src with spaces/leads file.txt:101:FIXME: safe lead 99'* ]] || exit 1
else
  [[ "$overflow" == *'zz global file.txt:21: [1 safe TODO lead omitted by global 120 candidate limit]'* ]] || exit 1
  [[ "$overflow" == *'src with spaces/leads file.txt:101:FIXME: safe lead 99'* ]] || exit 1
fi
[[ "$overflow" == *'src with spaces/leads file.txt:102: [1 safe TODO lead omitted by per-file 100 candidate limit]'* ]] || exit 1
[[ "$overflow" == *'src with spaces/leads file.txt:1: [1 sensitive TODO leads suppressed]'* ]] || exit 1
[[ "$overflow" != *'never-print-this-value'* ]] || exit 1

# Warnings themselves stay bounded when many files exceed their allowance.
mkdir -p "$fixture/many limits"
for file in {01..22}; do
  for number in {1..101}; do printf 'TODO: ordinary lead %d\n' "$number" >> "$fixture/many limits/file $file.txt"; done
done
many="$(bash "$skill/scripts/find-todos.sh" "$fixture/many limits")"
[[ "$(printf '%s\n' "$many" | grep -Ec '^file [0-9]{1,2}\.txt:101: \[1 safe TODO lead omitted by per-file 100 candidate limit\]$')" -eq 20 ]] || exit 1
[[ "$many" == *'2 additional files'*'safe TODO leads omitted'* ]] || exit 1
[[ "$(printf '%s\n' "$many" | grep -c 'safe TODO lead.*omitted')" -le 22 ]] || exit 1

non_git="$(bash "$skill/scripts/working-tree.sh" "$root")"
[[ "$non_git" == *'GIT=none'* ]] || exit 1
git -C "$root" init -q
git -C "$root" symbolic-ref HEAD refs/heads/fixture
empty_state="$(bash "$skill/scripts/working-tree.sh" "$root")"
[[ "$empty_state" == *'BRANCH=fixture'* && "$empty_state" == *'HEAD=none'* ]] || exit 1
git -C "$root" add src/payments.go
git -C "$root" -c user.name=Fixture -c user.email=fixture@example.test commit -qm initial
printf 'more\n' >> "$root/src/payments.go"
git -C "$root" add src/payments.go
printf 'unstaged\n' >> "$root/src/payments.go"
printf 'untracked\n' > "$root/src/new-task.txt"
state="$(bash "$skill/scripts/working-tree.sh" "$root")"
[[ "$state" == *'BRANCH=fixture'* && "$state" == *'HEAD='* && "$state" == *'STATUS=MM'*'src/payments.go'* && "$state" == *'src/new-task.txt'* ]] || exit 1

cat > "$root/docs/backlog.md" <<'DOC'
# Project Backlog

## In Progress

## Todo

### BL-002 — Improve capture
- **Status:** Todo
- **Priority:** High
- **Context:** Payment capture failure in src/payments.go.
- **Tasks:**
  - [ ] Handle retryable errors.
- **Related:** None
- **Files:** src/payments.go
- **Depends on:** None
- **Blocked by:** None
- **Completion:** Not completed
  - **Completed on:** —
  - **Completion commit:** —
  - **Completion evidence:** —
  - **Completion notes:** —

## Blocked

## Needs Review

## Done

### BL-001 — Ship audit trail
- **Status:** Done
- **Priority:** Low
- **Context:** An audit trail was required.
- **Tasks:**
  - [x] Ship audit trail.
- **Related:** None
- **Files:** src/audit.go
- **Depends on:** None
- **Blocked by:** None
- **Completion:** Completed
  - **Completed on:** 2026-10-01
  - **Completion commit:** abc1234
  - **Completion evidence:** Commit abc1234
  - **Completion notes:** Released audit trail.

<!-- skill-state
output_sha256: FINGERPRINT
-->
DOC
# Hash the document with only the fingerprint value line removed, retaining its newline.
if command -v sha256sum >/dev/null 2>&1; then
  hash="$(sed '/^output_sha256: /s/^output_sha256: .*//' "$root/docs/backlog.md" | sha256sum)"
  hash="${hash%% *}"
else
  hash="$(sed '/^output_sha256: /s/^output_sha256: .*//' "$root/docs/backlog.md" | shasum -a 256)"
  hash="${hash%% *}"
fi
sed "s/output_sha256: FINGERPRINT/output_sha256: $hash/" "$root/docs/backlog.md" > "$fixture/valid.md"
cp "$fixture/valid.md" "$root/docs/backlog.md"
bash "$skill/scripts/validate-backlog.sh" "$root/docs/backlog.md"
bash "$fixture/standalone/to-backlog/scripts/validate-backlog.sh" "$root/docs/backlog.md"
cmp -s "$fixture/valid.md" "$root/docs/backlog.md"

reject() {
  if bash "$skill/scripts/validate-backlog.sh" "$root/docs/backlog.md" > /dev/null 2> "$fixture/validation.stderr"; then
    printf 'Backlog validator accepted %s\n' "$1" >&2
    exit 1
  fi
  if grep -Eqi 'top-secret-credential|connection-secret|live-secret|sk_live_12345678x|ghp_12345678x|github_pat_12345678x|actually secret value|still-secret|production-secret' "$fixture/validation.stderr"; then
    printf 'Backlog validator disclosed a suspected credential for %s\n' "$1" >&2
    exit 1
  fi
}
# Editing any item without updating its fingerprint must be rejected.
sed 's/Released audit trail/Removed completed record/' "$fixture/valid.md" > "$root/docs/backlog.md"
reject 'a modified completion record/fingerprint'
# Recompute fingerprints for structural-invalid cases so validation cannot pass on hash mismatch alone.
invalid() {
  sed "$1" "$fixture/valid.md" > "$fixture/invalid.md"
  if command -v sha256sum >/dev/null 2>&1; then
    digest="$(sed '/^output_sha256: /s/^output_sha256: .*//' "$fixture/invalid.md" | sha256sum)"
  else
    digest="$(sed '/^output_sha256: /s/^output_sha256: .*//' "$fixture/invalid.md" | shasum -a 256)"
  fi
  digest="${digest%% *}"
  sed "s/^output_sha256: .*/output_sha256: $digest/" "$fixture/invalid.md" > "$root/docs/backlog.md"
  cp "$root/docs/backlog.md" "$fixture/before-validation.md"
  if [[ "${3:-reject}" == accept ]]; then
    bash "$skill/scripts/validate-backlog.sh" "$root/docs/backlog.md"
  else
    reject "$2"
  fi
  cmp -s "$fixture/before-validation.md" "$root/docs/backlog.md"
}
invalid 's/BL-002/BL-001/' 'duplicate IDs'
invalid 's/\*\*Status:\*\* Todo/\*\*Status:\*\* Queued/' 'invalid status'
invalid 's/\*\*Priority:\*\* High/\*\*Priority:\*\* Urgent/' 'invalid priority'
invalid 's/\*\*Status:\*\* Todo/\*\*Status:\*\* Done/' 'section/status mismatch'
invalid 's/\*\*Completion evidence:\*\* Commit abc1234/\*\*Completion evidence:\*\* —/' 'lost completion evidence'
invalid 's|Payment capture failure in src/payments.go.|API_KEY=live-secret|' 'secret in backlog Context'
for token in sk_live_12345678x ghp_12345678x github_pat_12345678x; do
  invalid "s|Payment capture failure in src/payments.go.|Replace $token|" "standalone credential $token"
done
for key in PASSWORD DB_PASSWORD SERVICE_API_KEY CI_ACCESS_TOKEN APP_SECRET_KEY SESSION_TOKEN AWS_SECRET_ACCESS_KEY; do
  invalid "s|Payment capture failure in src/payments.go.|$key=top-secret-credential|" "credential assignment $key"
done
invalid 's|Payment capture failure in src/payments.go.|client_secret=live-client-credential|' 'client secret assignment'
invalid 's|Payment capture failure in src/payments.go.|OAUTH_CLIENT_SECRET: "quoted-client-credential"|' 'prefixed quoted client secret'
for scheme in postgres postgresql mysql mongodb mongodb+srv redis rediss amqp amqps http https; do
  invalid "s|Payment capture failure in src/payments.go.|$scheme://service:connection-secret@db.example.test/tasks|" "credential URL $scheme"
done
invalid 's|Payment capture failure in src/payments.go.|postgresql://service%3Aconnection-secret%40db.example.test/tasks|' 'percent-encoded URL user-info'
invalid 's|Payment capture failure in src/payments.go.|https://service%3Aconnection-secret@api.example.test/tasks|' 'percent-encoded URL colon'
invalid 's|Payment capture failure in src/payments.go.|https://service:connection-secret%40api.example.test/tasks|' 'percent-encoded URL at sign'
invalid 's|Payment capture failure in src/payments.go.|Notes: APP_SECRET_KEY: top-secret-credential|' 'prefixed colon assignment'
invalid 's|Handle retryable errors.|Replace SERVICE_API_KEY=top-secret-credential.|' 'credential in checklist task'
invalid 's|Improve capture|TOKEN=top-secret-credential|' 'credential in heading'
invalid 's|## Todo|## TOKEN=top-secret-credential|' 'credential in malformed section heading'
invalid 's|### BL-002|### TOKEN=top-secret-credential|' 'credential in malformed item ID'
invalid 's|\*\*Priority:\*\* High|\*\*Priority:\*\* DB_PASSWORD=top-secret-credential|' 'credential in invalid priority'
invalid 's|Payment capture failure in src/payments.go.|API_KEY=[REDACTED] and DB_PASSWORD name|' 'bracketed redaction and name' accept
invalid 's|Payment capture failure in src/payments.go.|API_KEY=[REDACTED VALUE] and DB_PASSWORD name|' 'bracketed redaction label with spaces' accept
invalid 's|Payment capture failure in src/payments.go.|API_KEY=[actually secret value] in examples|' 'unrecognized bracketed credential'
invalid 's|Payment capture failure in src/payments.go.|API_KEY=[REDACTED VALUE]still-secret|' 'redaction prefix followed by credential'
invalid 's|Payment capture failure in src/payments.go.|TODO: rotate DB_PASSWORD=[REDACTED VALUE],production-secret|' 'redaction comma followed by credential'
invalid 's|Payment capture failure in src/payments.go.|DB_PASSWORD=[REDACTED], fixture_credential|' 'redaction comma and spaced credential'
invalid 's|Payment capture failure in src/payments.go.|DB_PASSWORD=[REDACTED];actual-secret|' 'redaction semicolon followed by credential'
invalid 's|Payment capture failure in src/payments.go.|DB_PASSWORD="[REDACTED]"|' 'matching quoted placeholder' accept
invalid 's|Payment capture failure in src/payments.go.|DB_PASSWORD=[REDACTED]; APP_TOKEN=[masked]|' 'separate safe named assignments' accept
invalid 's|Payment capture failure in src/payments.go.|API_KEY=<redacted> and DB_PASSWORD name|' 'angle-bracket redaction and name' accept
invalid 's|Payment capture failure in src/payments.go.|Connect to https://service@api.example.test/tasks|' 'URL without password' accept
invalid 's|Payment capture failure in src/payments.go.|client_secret=[REDACTED] and OAUTH_CLIENT_SECRET="<redacted>"|' 'safe client secret placeholders' accept
cp "$fixture/valid.md" "$root/docs/backlog.md"
bash "$skill/scripts/validate-backlog.sh" "$root/docs/backlog.md"
printf 'Backlog shell scenarios passed.\n'
