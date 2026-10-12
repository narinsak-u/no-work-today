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

candidates="$(bash "$skill/scripts/find-todos.sh" "$root")"
[[ "$candidates" == *'src/payments.go:1:'*'Add retries'* ]] || exit 1
[[ "$candidates" == *'src/order file.go:1:'*'Preserve order'* ]] || exit 1
[[ "$candidates" == *'notes.txt:1:'*'migration blockers'* ]] || exit 1
[[ "$candidates" != *'vendor/'* && "$candidates" != *'node_modules/'* && "$candidates" != *'dist/'* && "$candidates" != *'generated/'* && "$candidates" != *'binary.dat'* && "$candidates" != *'docs/backlog.md'* ]] || exit 1

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
cmp -s "$fixture/valid.md" "$root/docs/backlog.md"

reject() {
  if bash "$skill/scripts/validate-backlog.sh" "$root/docs/backlog.md" > /dev/null 2>&1; then
    printf 'Backlog validator accepted %s\n' "$1" >&2
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
  reject "$2"
  cmp -s "$fixture/before-validation.md" "$root/docs/backlog.md"
}
invalid 's/BL-002/BL-001/' 'duplicate IDs'
invalid 's/\*\*Status:\*\* Todo/\*\*Status:\*\* Queued/' 'invalid status'
invalid 's/\*\*Priority:\*\* High/\*\*Priority:\*\* Urgent/' 'invalid priority'
invalid 's/\*\*Status:\*\* Todo/\*\*Status:\*\* Done/' 'section/status mismatch'
invalid 's/\*\*Completion evidence:\*\* Commit abc1234/\*\*Completion evidence:\*\* —/' 'lost completion evidence'
cp "$fixture/valid.md" "$root/docs/backlog.md"
bash "$skill/scripts/validate-backlog.sh" "$root/docs/backlog.md"
printf 'Backlog shell scenarios passed.\n'
