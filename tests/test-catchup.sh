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

scan="$(bash "$skill/scripts/scan-project.sh" "$fixture/my project")"
[[ "$scan" == *"package.json"* && "$scan" == *"apps/web"* ]]
[[ "$scan" != *"node_modules"* && "$scan" != *"dist/skip.ts"* && "$scan" != *"target/skip.ts"* ]]
stack="$(bash "$skill/scripts/detect-stack.sh" "$fixture/my project")"
[[ "$stack" == *"JavaScript"* && "$stack" == *"Next.js"* ]]
entrypoints="$(bash "$skill/scripts/find-entrypoints.sh" "$fixture/my project")"
[[ "$entrypoints" == *"src/main.rs"* && "$entrypoints" == *"apps/web/main.go"* ]]
[[ "$entrypoints" != *"node_modules"* ]]

mkdir -p "$fixture/rust only" "$fixture/go only"
printf '[package]\nname = "demo"\n' > "$fixture/rust only/Cargo.toml"
printf 'module example.test/demo\n' > "$fixture/go only/go.mod"
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/rust only")" == *"Rust"* ]]
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/go only")" == *"Go"* ]]

cat > "$fixture/my project/docs/overview.md" <<'DOC'
# Project Overview
## Purpose
Some purpose.
## Stack
Go and Rust.
## Architecture
A service.
## Application Flow
A request flows to a handler.
## Important Modules
Service.
## Important Files
Entrypoint.
## Data Flow
Request to store.
## External Dependencies
Unknown.
## Environment and Configuration
Unknown.
## Development Workflow
Unknown.
## Recommended Reading Order
Entrypoint first.
## Cautions
Unknown.
DOC
bash "$skill/scripts/validate-overview.sh" "$fixture/my project/docs/overview.md"
printf 'API_KEY=sk-test-secret\n' >> "$fixture/my project/docs/overview.md"
if bash "$skill/scripts/validate-overview.sh" "$fixture/my project/docs/overview.md" >/dev/null 2>&1; then
  printf 'Validator accepted exposed secret\n' >&2
  exit 1
fi
printf 'Catch-up shell scenarios passed.\n'
