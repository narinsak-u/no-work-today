#!/usr/bin/env bash
set -euo pipefail

skill="$(cd "$(dirname "$0")/../skills/to-catchup" && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/memory skill tests.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/my project/src" "$fixture/my project/apps/web" "$fixture/my project/node_modules" "$fixture/my project/dist" "$fixture/my project/target" "$fixture/my project/docs"
printf '{"dependencies":{"next":"14.0.0","react":"18.0.0"}}\n' > "$fixture/my project/package.json"
printf 'fn main() {}\n' > "$fixture/my project/src/main.rs"
printf 'package main\n' > "$fixture/my project/apps/web/main.go"
printf 'skip\n' > "$fixture/my project/node_modules/skip.ts"
printf 'skip\n' > "$fixture/my project/dist/skip.ts"
printf 'skip\n' > "$fixture/my project/target/skip.ts"
mkdir -p "$fixture/my project/.venv" "$fixture/my project/generated" "$fixture/my project/.worktrees"
printf 'skip\n' > "$fixture/my project/.venv/main.py"
printf 'skip\n' > "$fixture/my project/generated/main.py"
printf 'skip\n' > "$fixture/my project/.worktrees/main.py"

scan="$(bash "$skill/scripts/scan-project.sh" "$fixture/my project")"
[[ "$scan" == *"package.json"* && "$scan" == *"apps/web"* ]] || exit 1
[[ "$scan" != *"node_modules"* && "$scan" != *"dist/skip.ts"* && "$scan" != *"target/skip.ts"* && "$scan" != *".venv"* && "$scan" != *"generated"* && "$scan" != *".worktrees"* ]] || exit 1
stack="$(bash "$skill/scripts/detect-stack.sh" "$fixture/my project")"
[[ "$stack" == *"JavaScript"* && "$stack" == *"Next.js"* ]] || exit 1
entrypoints="$(bash "$skill/scripts/find-entrypoints.sh" "$fixture/my project")"
[[ "$entrypoints" == *"src/main.rs"* && "$entrypoints" == *"apps/web/main.go"* ]] || exit 1
[[ "$entrypoints" != *"node_modules"* && "$entrypoints" != *".venv"* && "$entrypoints" != *"generated"* && "$entrypoints" != *".worktrees"* ]] || exit 1

mkdir -p "$fixture/rust only" "$fixture/go only"
printf '[package]\nname = "demo"\n' > "$fixture/rust only/Cargo.toml"
printf 'module example.test/demo\n' > "$fixture/go only/go.mod"
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/rust only")" == *"Rust"* ]] || exit 1
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/go only")" == *"Go"* ]] || exit 1

mkdir -p "$fixture/svelte only" "$fixture/big workspace/.venv" "$fixture/big workspace/generated"
printf '{"dependencies":{"svelte":"5.0.0"}}\n' > "$fixture/svelte only/package.json"
svelte="$(bash "$skill/scripts/detect-stack.sh" "$fixture/svelte only")"
[[ "$svelte" == *'|Svelte'* && "$svelte" != *'SvelteKit'* ]] || exit 1
printf '{"dependencies":{"next":"1.0.0"}}\n' > "$fixture/big workspace/.venv/package.json"
printf '{"dependencies":{"next":"1.0.0"}}\n' > "$fixture/big workspace/generated/package.json"
for ((n=1; n<=130; n++)); do
  mkdir -p "$fixture/big workspace/apps/app-$n"
  printf '{"dependencies":{"react":"18.0.0"}}\n' > "$fixture/big workspace/apps/app-$n/package.json"
done
stack="$(bash "$skill/scripts/detect-stack.sh" "$fixture/big workspace")"
[[ "$(printf '%s\n' "$stack" | wc -l)" -le 121 && "$stack" == *'additional stack findings omitted'* ]] || exit 1
[[ "$stack" != *'.venv'* && "$stack" != *'generated'* ]] || exit 1

cat > "$fixture/my project/docs/overview.md" <<'DOC'
# Project Overview
## Purpose
A service that manages accounts.
## Project Tree
```text
src/        application code
tests/      automated checks
src/main.rs startup candidate (unverified)
```
## Workflow
```text
Observed: request → handler → response
Candidate: src/main.rs → runtime behavior needs verification
```
## Scripts
- `cargo test` — run tests (declared in Cargo.toml).
## Important Notes
- Authentication boundary: verify before changing protected handlers.
- Unknown: deployment behavior; inspect deployment configuration.
DOC
bash "$skill/scripts/validate-overview.sh" "$fixture/my project/docs/overview.md"
for heading in '## Project Tree' '## Workflow' '## Scripts' '## Important Notes'; do
  grep -Fxq "$heading" "$fixture/my project/docs/overview.md" || exit 1
done
[[ "$(grep -c '^## ' "$fixture/my project/docs/overview.md")" -eq 5 ]] || exit 1
grep -Fq 'Observed:' "$fixture/my project/docs/overview.md"
grep -Fq 'Candidate:' "$fixture/my project/docs/overview.md"
cp "$fixture/my project/docs/overview.md" "$fixture/clean-overview.md"
printf 'API_KEY=sk-test-secret\n' >> "$fixture/my project/docs/overview.md"
if bash "$skill/scripts/validate-overview.sh" "$fixture/my project/docs/overview.md" >/dev/null 2>&1; then
  printf 'Validator accepted exposed secret\n' >&2
  exit 1
fi
cp "$fixture/clean-overview.md" "$fixture/my project/docs/overview.md"
printf 'password=secretvalue\n' >> "$fixture/my project/docs/overview.md"
if bash "$skill/scripts/validate-overview.sh" "$fixture/my project/docs/overview.md" >/dev/null 2>&1; then
  printf 'Validator accepted lowercase password\\n' >&2; exit 1
fi
cp "$fixture/clean-overview.md" "$fixture/my project/docs/overview.md"
printf 'GITHUB_TOKEN=ghp_exampletoken123456\\n' >> "$fixture/my project/docs/overview.md"
if bash "$skill/scripts/validate-overview.sh" "$fixture/my project/docs/overview.md" >/dev/null 2>&1; then
  printf 'Validator accepted token value\\n' >&2; exit 1
fi
cat > "$fixture/my project/docs/overview.md" <<'DOC'
# Project Overview
## Purpose
A fictional service.
## Project Tree
```text
src/
```
## Workflow
```text
request → service → response
```
## Scripts
- `pnpm prisma:migrate` — changes the database; confirm the target database before running.
- `node scripts/export.js` — writes an export file; review its destination first.
## Important Notes
- Use `DATABASE_URL=[REDACTED]` in examples; never copy a live connection string.
DOC
bash "$skill/scripts/validate-overview.sh" "$fixture/my project/docs/overview.md"
grep -Fq 'changes the database; confirm the target database before running' "$fixture/my project/docs/overview.md"
grep -Fq 'review its destination first' "$fixture/my project/docs/overview.md"
for unsafe in \
  'postgresql://reader:catchupUserInfoSecret29@db.example.test/app' \
  'SERVICE_DATABASE_PASSWORD=catchupAssignmentSecret29' \
  'SERVICE_API_KEY=x' \
  'TOKEN=abcde' \
  'DATABASE_URL=[REDACTED], actual-secret'; do
  cp "$fixture/my project/docs/overview.md" "$fixture/candidate.md"
  printf '%s\n' "$unsafe" >> "$fixture/candidate.md"
  if bash "$skill/scripts/validate-overview.sh" "$fixture/candidate.md" >/dev/null 2>&1; then
    printf 'Validator accepted unsafe credential example: %s\n' "$unsafe" >&2
    exit 1
  fi
done
for safe in 'API_KEY=[REDACTED]' 'SERVICE_TOKEN=<YOUR TOKEN>'; do
  cp "$fixture/my project/docs/overview.md" "$fixture/candidate.md"
  printf '%s\n' "$safe" >> "$fixture/candidate.md"
  bash "$skill/scripts/validate-overview.sh" "$fixture/candidate.md"
done
cp "$fixture/my project/docs/overview.md" "$fixture/fingerprinted.md"
cat >> "$fixture/fingerprinted.md" <<'DOC'
<!-- skill-state
output_sha256: FINGERPRINT
-->
DOC
digest="$(LC_ALL=C sed '/^output_sha256: /d' "$fixture/fingerprinted.md" | (sha256sum 2>/dev/null || shasum -a 256) | awk '{print $1}')"
awk -v digest="$digest" '{sub(/output_sha256: FINGERPRINT/, "output_sha256: " digest); print}' "$fixture/fingerprinted.md" > "$fixture/signed-overview.md"
bash "$skill/scripts/validate-overview.sh" "$fixture/signed-overview.md"
cp "$fixture/signed-overview.md" "$fixture/stale-overview.md"
printf 'User edit\n' >> "$fixture/stale-overview.md"
cp "$fixture/stale-overview.md" "$fixture/stale-before.md"
if bash "$skill/scripts/validate-overview.sh" "$fixture/stale-overview.md" >/dev/null 2>&1; then
  printf 'Validator accepted a stale overview fingerprint\n' >&2
  exit 1
fi
cmp "$fixture/stale-before.md" "$fixture/stale-overview.md"
printf 'Catch-up shell scenarios passed.\n'
