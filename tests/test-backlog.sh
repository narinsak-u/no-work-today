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
printf '// TODO: Remove debug log\n' > "$root/src/trivial.go"
printf 'TODO: vendored task\n' > "$root/vendor/dependency.go"
printf 'TODO: dependency task\n' > "$root/node_modules/library.js"
printf 'TODO: built task\n' > "$root/dist/output.js"
printf 'TODO: generated task\n' > "$root/generated/schema.go"
printf 'TODO: fake embedded binary\000more data\n' > "$root/src/binary.dat"
printf 'TODO: oversized task\n' > "$root/src/oversized.dat"
dd if=/dev/zero bs=1024 count=513 2>/dev/null >> "$root/src/oversized.dat"
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
scan_path="$fixture/scan-path"
mkdir -p "$scan_path"
real_wc="$(command -v wc)"
cat > "$scan_path/wc" <<'WC'
#!/usr/bin/env bash
printf 'wc\n' >> "$WC_MARKER"
exec "$REAL_WC" "$@"
WC
chmod +x "$scan_path/wc"
WC_MARKER="$fixture/wc-calls" REAL_WC="$real_wc" PATH="$scan_path:$PATH" \
  bash "$skill/scripts/find-todos.sh" "$root" > "$fixture/wc-scan"
[[ ! -s "$fixture/wc-calls" ]] || exit 1
[[ "$(cat "$fixture/wc-scan")" == "$candidates" ]] || exit 1
[[ "$candidates" == *'src/payments.go:1:'*'Add retries'* ]] || exit 1
[[ "$candidates" == *'src/order file.go:1:'*'Preserve order'* ]] || exit 1
[[ "$candidates" == *'notes.txt:1:'*'migration blockers'* ]] || exit 1
[[ "$candidates" == *'src/trivial.go:1:'*'Remove debug log'* ]] || exit 1
[[ "$candidates" != *'vendor/'* && "$candidates" != *'node_modules/'* && "$candidates" != *'dist/'* && "$candidates" != *'generated/'* && "$candidates" != *'binary.dat'* && "$candidates" != *'docs/backlog.md'* && "$candidates" != *'live-secret'* ]] || exit 1
[[ "$candidates" != *'oversized.dat'* ]] || exit 1
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
# Following the first omitted location scans only that file, from the given
# line, with the same sensitive-line redaction and per-call bound.
printf 'TODO: SERVICE_API_KEY=followup-secret\n' >> "$fixture/limits/src with spaces/leads file.txt"
printf 'TODO: finish payment replay coverage\n' >> "$fixture/limits/src with spaces/leads file.txt"
followup="$(bash "$skill/scripts/find-todos.sh" "$fixture/limits" 'src with spaces/leads file.txt' 102)"
[[ "$followup" == *'leads file.txt:102:FIXME: safe lead 100'* && "$followup" == *'leads file.txt:103:'*'sensitive TODO'* && "$followup" == *'leads file.txt:104:TODO: finish payment replay coverage'* ]] || exit 1
[[ "$followup" != *'followup-secret'* && "$followup" != *'leads file.txt:101:FIXME'* ]] || exit 1
if bash "$skill/scripts/find-todos.sh" "$fixture/limits" '../my project/notes.txt' 1 > "$fixture/unsafe-scan.out" 2> "$fixture/unsafe-scan.err"; then exit 1; fi
[[ ! -s "$fixture/unsafe-scan.out" ]] || exit 1


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
# A repository-configured fsmonitor command must not run during inspection.
fsmonitor_marker="$fixture/fsmonitor-invoked"
fsmonitor="$fixture/fsmonitor"
printf '#!/usr/bin/env bash\ntouch %q\nprintf "token\\n"\n' "$fsmonitor_marker" > "$fsmonitor"
chmod +x "$fsmonitor"
printf -v fsmonitor_command '%q' "$fsmonitor"
git -C "$root" config core.fsmonitor "$fsmonitor_command"
FSMONITOR_MARKER="$fsmonitor_marker" bash "$skill/scripts/working-tree.sh" "$root" >/dev/null
[[ ! -e "$fsmonitor_marker" ]] || { echo 'working-tree inspection invoked configured fsmonitor' >&2; exit 1; }
# This same repository has numerous low-value TODOs, one concrete capture
# outcome, and local staged/unstaged changes. The backlog below must not
# promote noise or infer Done from the local diff.
for number in {1..125}; do printf '// TODO: tweak formatting %d\n' "$number" >> "$root/src/noise.go"; done
noise_scan="$(bash "$fixture/standalone/to-backlog/scripts/find-todos.sh" "$root")"
[[ "$noise_scan" == *'src/noise.go:101:'*'safe TODO leads omitted by per-file 100 candidate limit'* ]] || exit 1
noise_followup="$(bash "$fixture/standalone/to-backlog/scripts/find-todos.sh" "$root" src/noise.go 101)"
[[ "$noise_followup" == *'src/noise.go:125:// TODO: tweak formatting 125'* ]] || exit 1
printf 'more\n' >> "$root/src/payments.go"
git -C "$root" add src/payments.go
printf 'unstaged\n' >> "$root/src/payments.go"
printf 'untracked\n' > "$root/src/new-task.txt"
state="$(bash "$skill/scripts/working-tree.sh" "$root")"
[[ "$state" == *'BRANCH=fixture'* && "$state" == *'HEAD='* && "$state" == *'STATUS=MM'*'src/payments.go'* && "$state" == *'src/new-task.txt'* ]] || exit 1
# Stage and edit a path with spaces; staged facts must not swallow unstaged
# facts, and no working-tree helper invocation changes the index or files.
printf 'first change\n' >> "$root/src/order file.go"
git -C "$root" add 'src/order file.go'
printf 'second change\n' >> "$root/src/order file.go"
before_index="$(git -C "$root" ls-files -s)"
before_status="$(git -C "$root" status --porcelain)"
state="$(bash "$skill/scripts/working-tree.sh" "$root")"
[[ "$state" == *'STAGED_CHANGED_FILES'*'src/order file.go'* && "$state" == *'UNSTAGED_CHANGED_FILES'*'src/order file.go'* ]] || exit 1
[[ "$state" == *'STAGED_DIFF_STAT'*'src/order file.go'* && "$state" == *'UNSTAGED_DIFF_STAT'*'src/order file.go'* ]] || exit 1
[[ "$state" == *'src/payments.go'* && "$state" == *'src/new-task.txt'* ]] || exit 1
[[ "$(git -C "$root" ls-files -s)" == "$before_index" && "$(git -C "$root" status --porcelain)" == "$before_status" ]] || exit 1
mkdir -p "$fixture/many changes"
git -C "$fixture/many changes" init -q
for number in {01..45}; do printf 'baseline\n' > "$fixture/many changes/file $number.txt"; done
git -C "$fixture/many changes" add .
git -C "$fixture/many changes" -c user.name=Fixture -c user.email=fixture@example.test commit -qm baseline
for number in {01..45}; do
  printf 'staged\n' >> "$fixture/many changes/file $number.txt"
  git -C "$fixture/many changes" add "file $number.txt"
  printf 'unstaged\n' >> "$fixture/many changes/file $number.txt"
done
many_changes="$(bash "$skill/scripts/working-tree.sh" "$fixture/many changes")"
[[ "$many_changes" == *'additional staged changed files omitted'* && "$many_changes" == *'additional unstaged changed files omitted'* ]] || exit 1
[[ "$many_changes" == *'STAGED_DIFF_STAT'* && "$many_changes" == *'UNSTAGED_DIFF_STAT'* ]] || exit 1

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
- **Files:** src/payments.go


## Blocked

## Needs Review

## Done

### BL-001 — Ship audit trail
- **Status:** Done
- **Priority:** Low
- **Context:** An audit trail was required.
- **Tasks:**
  - [x] Ship audit trail.
- **Files:** src/audit.go
- **Completion:** Completed
  - **Completed on:** 2026-10-01
  - **Completion commit:** abc1234
  - **Completion evidence:** Commit abc1234 contains the verified audit trail diff.
  - **Completion notes:** Released audit trail.

### BL-005 — Publish deployment checklist
- **Status:** Done
- **Priority:** Low
- **Context:** Operators needed a release checklist.
- **Tasks:**
  - [x] Publish the deployment checklist.
- **Completion:** Completed
  - **Completed on:** 2026-10-02
  - **Completion evidence:** Verified diff docs/deploy.md added the release checklist.

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
bash "$fixture/standalone/to-backlog/scripts/validate-backlog.sh" "$fixture/valid.md" "$fixture/valid.md"
[[ "$(grep -c '^### BL-' "$fixture/valid.md")" -eq 3 ]] || exit 1
[[ "$(grep -c '^  - \*\*Completion evidence:\*\*' "$fixture/valid.md")" -eq 2 ]] || exit 1
! grep -Fq 'Remove debug log' "$fixture/valid.md" || exit 1

reject() {
  if bash "$skill/scripts/validate-backlog.sh" "$root/docs/backlog.md" > /dev/null 2> "$fixture/validation.stderr"; then
    printf 'Backlog validator accepted %s\n' "$1" >&2
    exit 1
  fi
  if grep -Eqi 'top-secret-credential|connection-secret|live-secret|live-client-credential|quoted-client-credential|sk_live_12345678x|ghp_12345678x|github_pat_12345678x|actually secret value|still-secret|production-secret|backlogged-secret-credential' "$fixture/validation.stderr"; then
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
invalid 's/\*\*Completion evidence:\*\* Commit abc1234 contains the verified audit trail diff\./\*\*Completion evidence:\*\* —/' 'lost completion evidence'
invalid '/^- \*\*Context:\*\* Payment capture failure in src\/payments.go\.$/d' 'missing evidence-backed Context'
invalid '/^- \*\*Tasks:\*\*$/d' 'missing finite Tasks field'
invalid 's/\*\*Completion evidence:\*\* Commit abc1234 contains the verified audit trail diff\./\*\*Completion evidence:\*\* Not run/' 'unverified completion evidence'
# Re-sign changed documents before testing cross-version preservation:
# a fingerprint proves ownership, not continuity of IDs or completed records.
sign_update() {
  if command -v sha256sum >/dev/null 2>&1; then
    digest="$(sed '/^output_sha256: /s/^output_sha256: .*//' "$1" | sha256sum)"
  else
    digest="$(sed '/^output_sha256: /s/^output_sha256: .*//' "$1" | shasum -a 256)"
  fi
  digest="${digest%% *}"
  sed "s/^output_sha256: .*/output_sha256: $digest/" "$1" > "$root/docs/backlog.md"
}
reject_update() {
  if bash "$fixture/standalone/to-backlog/scripts/validate-backlog.sh" "$root/docs/backlog.md" "${2:-$fixture/valid.md}" > /dev/null 2> "$fixture/update.stderr"; then
    printf 'Backlog update validator accepted %s\n' "$1" >&2
    exit 1
  fi
}
awk '/^## Todo$/{print "## Blocked";next} /^## Blocked$/{print "## Todo";next} {print}' "$fixture/valid.md" |
  sed 's/\*\*Status:\*\* Todo/\*\*Status:\*\* Blocked/' > "$fixture/unsigned-update.md"
sign_update "$fixture/unsigned-update.md"
reject 'Blocked item without blocker'
sed 's/BL-002/BL-004/' "$fixture/valid.md" > "$fixture/unsigned-update.md"
sign_update "$fixture/unsigned-update.md"
bash "$skill/scripts/validate-backlog.sh" "$root/docs/backlog.md"
reject_update 'renumbered ID despite a valid new fingerprint'
sed '/^### BL-001 — Ship audit trail/,/^<!-- skill-state/{ /^<!-- skill-state/!d; }' "$fixture/valid.md" > "$fixture/unsigned-update.md"
sign_update "$fixture/unsigned-update.md"
bash "$skill/scripts/validate-backlog.sh" "$root/docs/backlog.md"
reject_update 'removed completed ID despite a valid new fingerprint'
sed '/^### BL-002 — Improve capture/,/^## Blocked/{ /^## Blocked/!d; }' "$fixture/valid.md" > "$fixture/unsigned-update.md"
sign_update "$fixture/unsigned-update.md"
bash "$skill/scripts/validate-backlog.sh" "$root/docs/backlog.md"
reject_update 'removed unfinished ID despite a valid new fingerprint'
sed 's/Commit abc1234 contains the verified audit trail diff\./Unrelated purported evidence./' "$fixture/valid.md" > "$fixture/unsigned-update.md"
sign_update "$fixture/unsigned-update.md"
reject_update 'replaced prior completion evidence'
sed 's/\*\*Completion notes:\*\* Released audit trail\./\*\*Completion notes:\*\* —/' "$fixture/valid.md" > "$fixture/unsigned-update.md"
sign_update "$fixture/unsigned-update.md"
reject_update 'removed prior completion notes'
sed 's/Verified diff docs\/deploy.md added the release checklist\./Unrelated purported evidence./' "$fixture/valid.md" > "$fixture/unsigned-update.md"
sign_update "$fixture/unsigned-update.md"
reject_update 'replaced second completed record'
cat > "$fixture/unsigned-update.md" <<'DOC'
# Project Backlog

## In Progress

### BL-002 — Retry failed payment capture
- **Status:** In Progress
- **Priority:** High
- **Context:** Payment capture failure in src/payments.go; active work is confirmed in the staged changes.
- **Tasks:**
  - [ ] Handle retryable errors.
- **Files:** src/payments.go

## Todo

### BL-003 — Address replay ordering
- **Status:** Todo
- **Priority:** Low
- **Context:** src/order file.go marks order loss during replay.
- **Tasks:**
  - [ ] Preserve ordering in replay.

## Blocked

## Needs Review

## Done

### BL-001 — Ship audit trail
- **Status:** Done
- **Priority:** Low
- **Context:** An audit trail was required.
- **Tasks:**
  - [x] Ship audit trail.
- **Files:** src/audit.go
- **Completion:** Completed
  - **Completed on:** 2026-10-01
  - **Completion commit:** abc1234
  - **Completion evidence:** Commit abc1234 contains the verified audit trail diff.
  - **Completion notes:** Released audit trail.

### BL-005 — Publish deployment checklist
- **Status:** Done
- **Priority:** Low
- **Context:** Operators needed a release checklist.
- **Tasks:**
  - [x] Publish the deployment checklist.
- **Completion:** Completed
  - **Completed on:** 2026-10-02
  - **Completion evidence:** Verified diff docs/deploy.md added the release checklist.

<!-- skill-state
output_sha256: FINGERPRINT
-->
DOC
sign_update "$fixture/unsigned-update.md"
bash "$fixture/standalone/to-backlog/scripts/validate-backlog.sh" "$root/docs/backlog.md" "$fixture/valid.md"
[[ "$(grep -c '^### BL-' "$root/docs/backlog.md")" -eq 4 ]] || exit 1
[[ "$(grep -c '^  - \*\*Completion evidence:\*\*' "$root/docs/backlog.md")" -eq 2 ]] || exit 1
cp "$root/docs/backlog.md" "$fixture/current-update.md"
sed -e 's/BL-002/BL-TMP/g' -e 's/BL-003/BL-002/g' -e 's/BL-TMP/BL-003/g' "$fixture/current-update.md" > "$fixture/unsigned-update.md"
sign_update "$fixture/unsigned-update.md"
bash "$skill/scripts/validate-backlog.sh" "$root/docs/backlog.md"
reject_update 'swapped existing IDs despite unchanged set' "$fixture/current-update.md"
cp "$fixture/current-update.md" "$root/docs/backlog.md"
sed '/^<!-- skill-state$/,/^-->$/d' "$fixture/valid.md" > "$fixture/legacy-before.md"
bash "$fixture/standalone/to-backlog/scripts/validate-backlog.sh" "$root/docs/backlog.md" "$fixture/legacy-before.md"
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
invalid 's|Payment capture failure in src/payments.go.|Authorization: Bearer backlogged-secret-credential|' 'Bearer authorization credential'
invalid 's|Payment capture failure in src/payments.go.|Authorization: Bearer [REDACTED]|' 'redacted Bearer authorization credential' accept
# GitHub issue collection uses an offline gh stub and publishes only complete
# results from a successful paginated API request.
collector="$skill/scripts/list-open-issues.sh"
gh_stub="$fixture/gh-bin"
mkdir -p "$gh_stub"
cat > "$gh_stub/gh" <<'GH'
#!/usr/bin/env bash
printf '%s\n' "$PWD" > "$GH_CALL_DIR"
printf '%s\n' "$@" > "$GH_CALL_ARGS"
case "${GH_MODE:-success}" in
  partial)
    printf '%s\n' '{"number":99,"title":"Partial page","body":null,"labels":[],"url":"https://github.com/example/project/issues/99}'
    exit 1
    ;;
  repo-error) printf 'not a GitHub repository\n' >&2; exit 1 ;;
  auth-error) printf 'authentication required\n' >&2; exit 1 ;;
esac
printf '%s' "$GH_FIXTURE"
GH
chmod +x "$gh_stub/gh"
issue_fixture='{"number":12,"title":"Improve retry behavior","body":"Retry transient failures","labels":["bug","wontfix"],"url":"https://github.com/example/project/issues/12}
{"number":13,"title":"Document recovery","body":null,"labels":[],"url":"https://github.com/example/project/issues/13}'
GH_CALL_DIR="$fixture/gh-cwd" GH_CALL_ARGS="$fixture/gh-args" GH_FIXTURE="$issue_fixture" PATH="$gh_stub:$PATH" \
  bash "$collector" "$root" > "$fixture/issues.out" 2> "$fixture/issues.err"
[[ "$(cat "$fixture/gh-cwd")" == "$(cd "$root" && pwd -P)" ]] || exit 1
args="$(cat "$fixture/gh-args")"
[[ "$args" == *'--paginate'* && "$args" == *'state=open&per_page=100'* && "$args" == *'pull_request == null'* ]] || exit 1
[[ "$(cat "$fixture/issues.out")" == "$issue_fixture" ]] || exit 1
for mode in partial repo-error auth-error; do
  if GH_CALL_DIR="$fixture/gh-cwd" GH_CALL_ARGS="$fixture/gh-args" GH_FIXTURE= GH_MODE="$mode" PATH="$gh_stub:$PATH" \
    bash "$collector" "$root" > "$fixture/issues.out" 2> "$fixture/issues.err"; then exit 1; fi
  [[ ! -s "$fixture/issues.out" ]] || exit 1
done
if GH_CALL_DIR="$fixture/gh-cwd" GH_CALL_ARGS="$fixture/gh-args" GH_FIXTURE= PATH="$fixture/no-gh" \
  bash "$collector" "$root" > "$fixture/issues.out" 2> "$fixture/issues.err"; then exit 1; fi
[[ ! -s "$fixture/issues.out" ]] || exit 1
cp "$fixture/valid.md" "$root/docs/backlog.md"
bash "$skill/scripts/validate-backlog.sh" "$root/docs/backlog.md"
printf 'Backlog shell scenarios passed.\n'
