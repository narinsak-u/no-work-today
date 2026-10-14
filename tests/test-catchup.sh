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
## 1. Purpose
A service that manages accounts.
<<<<<<< HEAD
## 2. Tech Stack
Unknown.
## 3. Architecture
Application handles requests.
## 4. Main Flows
### 🔁 Request
Observed: the request reaches a handler and returns a response.
=======
## Tech Stack

JavaScript and Next.js are declared in the fixture manifest.
## Project Tree
>>>>>>> d910d8d (feat: improve catchup overview inventories)
```text
Request
  |
  v
Handler
  |
  v
Response
```
### 🔎 Candidate
Candidate: the entrypoint is a lead, not a verified runtime path.
```text
src/main.rs
  |
  v
Needs verification
```
<<<<<<< HEAD
## 5. Core Modules
`src/` contains application code.
## 6. Important Files
`src/main.rs` is a candidate.
## 7. Data & External Services
Unknown.
## 8. Development Workflow
`cargo test` — run tests (declared in Cargo.toml).
## 9. Start Here
Read `src/main.rs`, then tests.
## 10. Important Notes
=======

## API Endpoints

Confirmed count: 1 (fixture example).

| Method | Path | Purpose | Access |
|---|---|---|---|
| GET | /health | Liveness | Public |
## Scripts
- `cargo test` — run tests (declared in Cargo.toml).
## Important Notes
>>>>>>> d910d8d (feat: improve catchup overview inventories)
- Authentication boundary: verify before changing protected handlers.
- Unknown: deployment behavior; inspect deployment configuration.
DOC
bash "$skill/scripts/validate-overview.sh" "$fixture/my project/docs/overview.md"
<<<<<<< HEAD
for heading in '## 1. Purpose' '## 5. Core Modules' '## 6. Important Files' '## 8. Development Workflow' '## 10. Important Notes'; do
  grep -Fxq "$heading" "$fixture/my project/docs/overview.md" || exit 1
done
[[ "$(grep -c '^## ' "$fixture/my project/docs/overview.md")" -eq 10 ]] || exit 1
[[ "$(grep -c '^### ' "$fixture/my project/docs/overview.md")" -eq 2 ]] || exit 1
[[ "$(grep -c '^  |$' "$fixture/my project/docs/overview.md")" -ge 2 ]] || exit 1
=======
for heading in '## Tech Stack' '## Project Tree' '## Workflow' '## API Endpoints' '## Scripts' '## Important Notes'; do
  grep -Fxq "$heading" "$fixture/my project/docs/overview.md" || exit 1
done
[[ "$(grep -c '^## ' "$fixture/my project/docs/overview.md")" -eq 7 ]] || exit 1
>>>>>>> d910d8d (feat: improve catchup overview inventories)
grep -Fq 'Observed:' "$fixture/my project/docs/overview.md"
grep -Fq 'Candidate:' "$fixture/my project/docs/overview.md"
cat > "$fixture/my project/docs/overview.md" <<'DOC'
# Project Overview
## 1. Purpose
A fictional service.
<<<<<<< HEAD
## 2. Tech Stack
Unknown.
## 3. Architecture
Application handles requests.
## 4. Main Flows
=======
## Tech Stack

Node.js with an HTTP framework (fixture evidence).
## Project Tree
```text
src/
```
## Workflow
```text
>>>>>>> d910d8d (feat: improve catchup overview inventories)
request → service → response
## 5. Core Modules
`src/` contains application code.
## 6. Important Files
`src/main.rs`.
## 7. Data & External Services
Unknown.
## 8. Development Workflow
- `pnpm prisma:migrate` — changes the database; confirm the target database before running.
- `node scripts/export.js` — writes an export file; review its destination first.
## 9. Start Here
Read `src/main.rs`.
## 10. Important Notes
- Use `DATABASE_URL=[REDACTED]` in examples; never copy a live connection string.
DOC
bash "$skill/scripts/validate-overview.sh" "$fixture/my project/docs/overview.md"

mkdir -p "$fixture/client/docs"
cat > "$fixture/client/docs/overview.md" <<'DOC'
# Project Overview
## Purpose
A browser client.
## Tech Stack
TypeScript, React, and Vite.
## Project Tree
src/ browser application
## Workflow
```text
Open app
  ↓
Search notes
```
## Scripts
- `npm run dev` — start local development.
## Important Notes
- The API implementation lives in another repository; server routes are not available here.
DOC
bash "$skill/scripts/validate-overview.sh" "$fixture/client/docs/overview.md"
grep -Fq 'changes the database; confirm the target database before running' "$fixture/my project/docs/overview.md"
grep -Fq 'review its destination first' "$fixture/my project/docs/overview.md"
reject_file() {
  local label="$1" candidate="$2" sensitive="$3" diagnostic
  cp "$candidate" "$fixture/submitted-before.md"
  if diagnostic="$(bash "$skill/scripts/validate-overview.sh" "$candidate" 2>&1)"; then
    printf 'Validator accepted %s\n' "$label" >&2
    exit 1
  fi
  [[ -z "$sensitive" || "$diagnostic" != *"$sensitive"* ]] || {
    printf 'Validator disclosed the unsafe value while rejecting %s\n' "$label" >&2
    exit 1
  }
  cmp "$fixture/submitted-before.md" "$candidate"
}
cp "$fixture/my project/docs/overview.md" "$fixture/missing-section.md"
sed -i '/^## 7\. Data & External Services$/d' "$fixture/missing-section.md"
reject_file 'missing major section' "$fixture/missing-section.md" ''
cp "$fixture/my project/docs/overview.md" "$fixture/extra-section.md"
sed -i '/^## 10\. Important Notes$/i ## Appendix' "$fixture/extra-section.md"
reject_file 'extra major section' "$fixture/extra-section.md" ''
cp "$fixture/my project/docs/overview.md" "$fixture/reordered-section.md"
awk '
  /^## 2\. Tech Stack$/ { print "## 3. Architecture"; print; skip=1; next }
  /^## 3\. Architecture$/ && skip { next }
  { print }
' "$fixture/reordered-section.md" > "$fixture/reordered.tmp"
mv "$fixture/reordered.tmp" "$fixture/reordered-section.md"
reject_file 'reordered major section' "$fixture/reordered-section.md" ''
cp "$fixture/my project/docs/overview.md" "$fixture/merged-heading.md"
awk '
  /^# Project Overview$/ { print; next }
  /^## 1\. Purpose$/ { print "## 1. Purpose ## 2. Tech Stack"; next }
  /^A service that manages accounts\.$/ { next }
  /^## 2\. Tech Stack$/ { next }
  /^Unknown\.$/ && !unknown_seen++ { next }
  { print }
' "$fixture/merged-heading.md" > "$fixture/merged-heading.tmp"
mv "$fixture/merged-heading.tmp" "$fixture/merged-heading.md"
reject_file 'merged major heading line' "$fixture/merged-heading.md" ''
expect_validation() {
  local expectation="$1" label="$2" value="$3" diagnostic
  cp "$fixture/my project/docs/overview.md" "$fixture/candidate.md"
  printf '%s\n' "$value" >> "$fixture/candidate.md"
  if [[ "$expectation" == accept ]]; then
    bash "$skill/scripts/validate-overview.sh" "$fixture/candidate.md" ||
      { printf 'Validator rejected %s\n' "$label" >&2; exit 1; }
  else
    cp "$fixture/candidate.md" "$fixture/submitted-before.md"
    if diagnostic="$(bash "$skill/scripts/validate-overview.sh" "$fixture/candidate.md" 2>&1)"; then
      printf 'Validator accepted %s\n' "$label" >&2
      exit 1
    fi
    [[ "$diagnostic" != *"$value"* ]] || {
      printf 'Validator disclosed the unsafe value while rejecting %s\n' "$label" >&2
      exit 1
    }
    cmp "$fixture/submitted-before.md" "$fixture/candidate.md"
  fi
}

<<<<<<< HEAD
=======
cp "$fixture/my project/docs/overview.md" "$fixture/missing-tech-stack.md"
grep -Fv '## Tech Stack' "$fixture/missing-tech-stack.md" > "$fixture/missing-tech-stack.tmp"
mv "$fixture/missing-tech-stack.tmp" "$fixture/missing-tech-stack.md"
reject_file 'missing Tech Stack section' "$fixture/missing-tech-stack.md" ''
>>>>>>> d910d8d (feat: improve catchup overview inventories)
for unsafe in \
  'API_KEY=sk-test-secret' \
  'password=secretvalue' \
  'GITHUB_TOKEN=ghp_exampletoken123456' \
  'postgres://reader:catchupPostgresSecret29@db.example.test/app' \
  'postgresql://reader:catchupUserInfoSecret29@db.example.test/app' \
  'SERVICE_DATABASE_PASSWORD=catchupAssignmentSecret29' \
  'SERVICE_API_KEY=x' \
  'TOKEN=abcde' \
  'DATABASE_PASSWORD=[REDACTED], actual-secret' \
  'TOKEN=[REDACTED].secret'; do
  expect_validation reject 'unsafe credential example' "$unsafe"
done
for safe in 'API_KEY=[REDACTED]' 'SERVICE_TOKEN=<YOUR TOKEN>' 'TOKEN=[REDACTED].'; do
  expect_validation accept 'safe placeholder' "$safe"
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
reject_file 'stale overview fingerprint' "$fixture/stale-overview.md" ''

cp "$fixture/my project/docs/overview.md" "$fixture/misplaced-fingerprint.md"
printf 'output_sha256: %064d\n' 0 >> "$fixture/misplaced-fingerprint.md"
reject_file 'misplaced fingerprint' "$fixture/misplaced-fingerprint.md" ''
cp "$fixture/my project/docs/overview.md" "$fixture/duplicate-fingerprint.md"
cat >> "$fixture/duplicate-fingerprint.md" <<'DOC'
<!-- skill-state
output_sha256: 0000000000000000000000000000000000000000000000000000000000000000
output_sha256: 1111111111111111111111111111111111111111111111111111111111111111
-->
DOC
reject_file 'duplicate fingerprints' "$fixture/duplicate-fingerprint.md" ''

digest="$( (cat "$fixture/my project/docs/overview.md"; printf '<!-- skill-state\n-->') | (sha256sum 2>/dev/null || shasum -a 256) | awk '{print $1}')"
cat "$fixture/my project/docs/overview.md" > "$fixture/no-final-lf.md"
printf '<!-- skill-state\noutput_sha256: %s\n-->' "$digest" >> "$fixture/no-final-lf.md"
bash "$skill/scripts/validate-overview.sh" "$fixture/no-final-lf.md"
printf 'Catch-up shell scenarios passed.\n'
