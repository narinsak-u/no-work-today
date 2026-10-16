#!/usr/bin/env bash
set -euo pipefail

skill="$(cd "$(dirname "$0")/../skills/to-catchup" && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/memory skill tests.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
assert_role_described_stack() {
  local file="$1"
  awk '
    /^## Tech Stack$/ { in_stack = 1; next }
    /^## / && in_stack { exit }
    in_stack && NF {
      if ($0 !~ /^- \*\*[^*]+\*\*: .+\.$/) exit 1
      found = 1
    }
    END { if (!found) exit 1 }
  ' "$file" || { printf 'Tech Stack entries must be concise role-described names: %s\n' "$file" >&2; return 1; }
}

assert_workflow_diagrams_complete() {
  local file="$1" workflows diagrams blocks arrows
  workflows="$(awk '
    /^\| Workflow \| Purpose \|$/ { in_table = 1; next }
    /^###/ && in_table { exit }
    in_table && /^\| [^ -]/ { count++ }
    END { print count + 0 }
  ' "$file")"
  diagrams="$(awk '
    /^## Workflow$/ { in_workflow = 1; next }
    /^## / && in_workflow { exit }
    in_workflow && /^###/ { count++ }
    END { print count + 0 }
  ' "$file")"
  blocks="$(awk '
    /^## Workflow$/ { in_workflow = 1; next }
    /^## / && in_workflow { exit }
    in_workflow && /^```text$/ { count++ }
    END { print count + 0 }
  ' "$file")"
  arrows="$(awk '
    /^## Workflow$/ { in_workflow = 1; next }
    /^## / && in_workflow { exit }
    in_workflow && /^  ↓$/ { count++ }
    END { print count + 0 }
  ' "$file")"
  if [[ "$workflows" -eq 0 || "$workflows" -ne "$diagrams" ||
        "$diagrams" -ne "$blocks" || "$arrows" -lt "$blocks" ]]; then
    printf 'Workflow inventory/diagram mismatch in %s: %s names, %s headings, %s diagrams, %s vertical arrows\n' \
      "$file" "$workflows" "$diagrams" "$blocks" "$arrows" >&2
    return 1
  fi
}

assert_endpoint_count() {
  local file="$1" expected="$2" actual
  actual="$(awk '
    /^## API Endpoints$/ { in_api = 1; next }
    /^## / && in_api { exit }
    in_api && /^\| (GET|POST|PATCH|PUT|DELETE|HEAD|OPTIONS) \|/ { count++ }
    END { print count + 0 }
  ' "$file")"
  if [[ "$actual" -ne "$expected" ]] ||
    ! grep -Eq "^\\*\\*(Complete|Partial) — $expected (confirmed|fictional|registered) HTTP endpoints?" "$file"; then
    printf 'Endpoint inventory mismatch in %s: expected %s rows, found %s\n' "$file" "$expected" "$actual" >&2
    return 1
  fi
}

assert_complete_workflow_count() {
  local file="$1" expected="$2" actual
  actual="$(awk '
    /^\| Workflow \| Purpose \|$/ { in_table = 1; next }
    /^###/ && in_table { exit }
    in_table && /^\| [^ -]/ { count++ }
    END { print count + 0 }
  ' "$file")"
  [[ "$actual" -eq "$expected" ]] &&
    grep -Fq "**Complete — $expected" "$file"
}

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
A fictional account service helps team members manage access (`README.md`).
## Tech Stack
- **Rust**: Runs the account service (`src/main.rs`).
## Project Tree
```text
src/main.rs       service startup and mounted routes
apps/web/         browser client
tests/            behavior checks
```
Read `README.md` first for setup, then `src/main.rs` for route registration, then tests for behavior.
The browser client calls the account service; the service checks access before returning an account.
## Workflow
**Partial — 1 confirmed workflow; background triggers need verification.**
| Workflow | Purpose |
|---|---|
| View account | Check access and return an account to a member. |
### View account
```text
Member requests account
  ↓
Validate access
  ↓
Read account
  ↓
Return account
```
## API Endpoints
**Partial — 2 confirmed HTTP endpoints; admin routes need verification.**
| Method | Path | Purpose | Access |
|---|---|---|---|
| GET | `/api/accounts/:id` | Read an account | Authenticated |
| GET | `/health` | Liveness check | Public |
## Scripts
- `cargo test` — run tests (`Cargo.toml`); not exercised.
## Important Notes
- Authentication boundary: verify before changing protected handlers.
- Unknown: deployment behavior; inspect deployment configuration.
DOC
! grep -Fq 'React' "$fixture/my project/docs/overview.md"
! grep -Fq 'Next.js' "$fixture/my project/docs/overview.md"
bash "$skill/scripts/validate-overview.sh" "$fixture/my project/docs/overview.md"
assert_role_described_stack "$fixture/my project/docs/overview.md"
assert_workflow_diagrams_complete "$fixture/my project/docs/overview.md"
assert_endpoint_count "$fixture/my project/docs/overview.md" 2
[[ "$(grep -c '^## ' "$fixture/my project/docs/overview.md")" -eq 7 ]] || exit 1
grep -Fq 'Read `README.md` first' "$fixture/my project/docs/overview.md"
grep -Fq 'Partial — 2 confirmed HTTP endpoints' "$fixture/my project/docs/overview.md"

cat > "$fixture/my project/docs/overview.md" <<'DOC'
# Project Overview
## Purpose
A fictional service.
## Tech Stack
- **Node.js**: Runs the HTTP service.
- **Express**: Handles HTTP requests.
## Project Tree
```text
src/ service implementation
```
Read `README.md` before `src/` and its tests. The service checks requests before persisting records.
## Workflow
**Partial — 1 confirmed workflow; background jobs need verification.**
| Workflow | Purpose |
|---|---|
| Create record | Validate and save a record. |
### Create record
```text
Request
  ↓
Validate
  ↓
Save record
  ↓
Response
```
## API Endpoints
**Partial — 1 confirmed HTTP endpoint; admin routes need verification.**
| Method | Path | Purpose | Access |
|---|---|---|---|
| POST | `/records` | Create a record | Authenticated |
## Scripts
- `pnpm prisma:migrate` — changes the database; confirm the target database before running; not exercised.
- `node scripts/export.js` — writes an export file; review its destination first; not exercised.
## Important Notes
- Use `DATABASE_URL=[REDACTED]` in examples; never copy a live connection string.
DOC
assert_role_described_stack "$fixture/my project/docs/overview.md"
assert_workflow_diagrams_complete "$fixture/my project/docs/overview.md"
assert_endpoint_count "$fixture/my project/docs/overview.md" 1
bash "$skill/scripts/validate-overview.sh" "$fixture/my project/docs/overview.md"

mkdir -p "$fixture/client/docs"
cat > "$fixture/client/docs/overview.md" <<'DOC'
# Project Overview
## Purpose
A fictional browser client for finding notes.
## Tech Stack
- **TypeScript**: Adds types to the browser application.
- **React**: Builds the browser interface.
- **Vite**: Runs the local development server.
## Project Tree
src/ browser application; begin at `src/main.ts`, then read `src/search.ts`.
## Workflow
**Partial — 1 confirmed workflow; remote search implementation needs verification.**
| Workflow | Purpose |
|---|---|
| Search notes | Query a remote API and display results. |
### Search notes
```text
Open app
  ↓
Enter search
  ↓
Request remote results
  ↓
Render notes
```
## Scripts
- `npm run dev` — start local development; not exercised.
## Important Notes
- The API implementation lives in another repository; server routes are not available here.
DOC
bash "$skill/scripts/validate-overview.sh" "$fixture/client/docs/overview.md"
assert_role_described_stack "$fixture/client/docs/overview.md"
assert_workflow_diagrams_complete "$fixture/client/docs/overview.md"
[[ "$(grep -c '^## ' "$fixture/client/docs/overview.md")" -eq 6 ]] || exit 1
! grep -Fq '## API Endpoints' "$fixture/client/docs/overview.md"
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
awk '$0 != "## Tech Stack"' "$fixture/missing-section.md" > "$fixture/missing-section.tmp"
mv "$fixture/missing-section.tmp" "$fixture/missing-section.md"
reject_file 'missing major section' "$fixture/missing-section.md" ''
cp "$fixture/my project/docs/overview.md" "$fixture/extra-section.md"
awk '/^## Important Notes$/ { print "## Appendix" } { print }' "$fixture/extra-section.md" > "$fixture/extra-section.tmp"
mv "$fixture/extra-section.tmp" "$fixture/extra-section.md"
reject_file 'extra major section' "$fixture/extra-section.md" ''
cp "$fixture/my project/docs/overview.md" "$fixture/reordered-section.md"
awk '
  /^## Tech Stack$/ { print "## Project Tree"; print; skip=1; next }
  /^## Project Tree$/ && skip { next }
  { print }
' "$fixture/reordered-section.md" > "$fixture/reordered.tmp"
mv "$fixture/reordered.tmp" "$fixture/reordered-section.md"
reject_file 'reordered major section' "$fixture/reordered-section.md" ''
cp "$fixture/my project/docs/overview.md" "$fixture/merged-heading.md"
awk '
  /^## Purpose$/ { print "## Purpose ## Tech Stack"; next }
  /^## Tech Stack$/ { next }
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

cp "$fixture/my project/docs/overview.md" "$fixture/wrong-place-endpoints.md"
awk '
  /^## API Endpoints$/ { print "## Scripts"; next }
  /^## Scripts$/ { print "## API Endpoints"; next }
  { print }
' "$fixture/wrong-place-endpoints.md" > "$fixture/wrong-place.tmp"
mv "$fixture/wrong-place.tmp" "$fixture/wrong-place-endpoints.md"
reject_file 'misordered optional endpoints' "$fixture/wrong-place-endpoints.md" ''
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
# The published fictional example and generated-fixture shape share this validator.
bash "$skill/scripts/validate-overview.sh" "$skill/../../examples/overview.md"
assert_role_described_stack "$skill/../../examples/overview.md"
assert_workflow_diagrams_complete "$skill/../../examples/overview.md"
assert_complete_workflow_count "$skill/../../examples/overview.md" 5
assert_endpoint_count "$skill/../../examples/overview.md" 7
for helper in "$skill"/scripts/*.sh; do
  bash -n "$helper"
done
if grep -nE '^(<<<<<<< |=======|>>>>>>> )' "$skill/SKILL.md" "$skill/references/overview-template.md" "$skill"/scripts/*.sh "$skill/../../examples/overview.md" "$skill/../../GLOSSARY.md"; then
  printf 'Published catch-up files contain merge markers\n' >&2
  exit 1
fi
# A separately installed skill validates a signed overview against a representative
# repository. The document below is a fixture of expected agent prose, not a
# claim that shell helpers generate semantic explanations.
installed="$fixture/installed agent"
project="$fixture/evidenced notes"
mkdir -p "$installed" "$project/src" "$project/docs"
cp -R "$skill" "$installed/to-catchup"
cat > "$project/README.md" <<'DOC'
# Notes API
An example service for team members to save and read private notes.
Inspect src/server.js for HTTP registration and access checks before changes.
DOC
cat > "$project/package.json" <<'DOC'
{"scripts":{"test":"node --test"},"dependencies":{"express":"4.0.0"}}
DOC
cat > "$project/src/server.js" <<'DOC'
const express = require('express');
const app = express();
app.use(express.json());
const api = express.Router();
function requireMember(req, res, next) {
  const member = req.get('x-member-id');
  if (!member) return res.sendStatus(401);
  req.user = { id: member };
  next();
}
const notes = new Map();
api.post('/notes', requireMember, (req, res) => {
  const id = String(notes.size + 1);
  notes.set(id, { owner: req.user.id, body: req.body.body });
  res.status(201).json({ id });
});
api.get('/notes/:id', requireMember, (req, res) => {
  const note = notes.get(req.params.id);
  if (!note || note.owner !== req.user.id) return res.sendStatus(404);
  res.json(note);
});
app.use('/api', api);
app.get('/health', (req, res) => res.sendStatus(200));
module.exports = app;
DOC
installed_skill="$installed/to-catchup"
[[ "$(bash "$installed_skill/scripts/scan-project.sh" "$project")" == *'src/server.js'* ]] || exit 1
[[ "$(bash "$installed_skill/scripts/detect-stack.sh" "$project")" == *'Express'* ]] || exit 1
cat > "$project/docs/overview.md" <<'DOC'
# Project Overview
## Purpose
The Notes API lets team members save and read their private notes (`README.md`).
## Tech Stack
- **Node.js**: Runs the service.
- **Express**: Registers HTTP routes (`src/server.js`, `package.json`).
## Project Tree
```text
README.md       purpose and safety guidance
src/server.js   router, access checks, in-memory notes
package.json    test command and framework dependency
```
Start with `README.md`, follow `src/server.js` from route to response, then inspect `package.json` for the test command. The router checks membership before reading or writing the in-memory map.
## Workflow
**Complete — 2 verified workflows** in the inspected `src/server.js`.
| Workflow | Purpose |
|---|---|
| Save note | Authenticate a member and store a note. |
| Read note | Return a stored note only to its owner. |
### Save note
```text
POST /api/notes
  ↓
Require member
  ↓
Save note to in-memory map
  ↓
Return ID with 201
```
### Read note
```text
GET /api/notes/:id
  ↓
Require member
  ↓
Check stored owner
  ↓
Return note or 404
```
## API Endpoints
**Complete — 3 registered HTTP endpoints** (`src/server.js`).
| Method | Path | Purpose | Access |
|---|---|---|---|
| POST | `/api/notes` | Save a note | Authenticated |
| GET | `/api/notes/:id` | Read a note | Authenticated |
| GET | `/health` | Liveness check | Public |
## Scripts
- `npm test` — Node's test runner (`package.json`); not exercised.
## Important Notes
- The in-memory map loses notes when the process restarts; do not treat it as durable storage.
- `requireMember` trusts the `x-member-id` request header in this fixture; it is not production authentication. Replace it with verified identity before exposing real private notes.
- No database, queue, or deployment setup is evidenced. Deployment security is **Needs verification**.
<!-- skill-state
output_sha256: FINGERPRINT
-->
DOC
digest="$(LC_ALL=C sed '/^output_sha256: /d' "$project/docs/overview.md" | (sha256sum 2>/dev/null || shasum -a 256) | awk '{print $1}')"
awk -v digest="$digest" '{sub(/output_sha256: FINGERPRINT/, "output_sha256: " digest); print}' "$project/docs/overview.md" > "$project/docs/signed.md"
mv "$project/docs/signed.md" "$project/docs/overview.md"
bash "$installed_skill/scripts/validate-overview.sh" "$project/docs/overview.md"
assert_role_described_stack "$project/docs/overview.md"
assert_workflow_diagrams_complete "$project/docs/overview.md"
assert_complete_workflow_count "$project/docs/overview.md" 2
assert_endpoint_count "$project/docs/overview.md" 3
grep -Fq 'Start with `README.md`' "$project/docs/overview.md"
grep -Fq 'Needs verification' "$project/docs/overview.md"
[[ "$(find "$project/docs" -type f | wc -l | tr -d ' ')" -eq 1 ]] || exit 1
printf 'Catch-up shell scenarios passed.\n'
