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

# App Router pages and layouts are leads, including in a project with no main/index file.
mkdir -p "$fixture/my project/app/(dashboard)" "$fixture/my project/src/app/blog" \
  "$fixture/my project/node_modules/app" "$fixture/my project/dist/app" \
  "$fixture/my project/build/app" "$fixture/my project/.git/app" "$fixture/my project/generated/app"
for candidate in \
  "app/page.tsx" "app/(dashboard)/layout.jsx" \
  "src/app/page.js" "src/app/blog/layout.tsx" "src/index.ts"; do
  printf 'candidate\n' > "$fixture/my project/$candidate"
done
for excluded in node_modules dist build .git generated; do
  printf 'skip\n' > "$fixture/my project/$excluded/app/page.tsx"
done
entrypoints="$(bash "$skill/scripts/find-entrypoints.sh" "$fixture/my project")"
for candidate in \
  "app/page.tsx" "app/(dashboard)/layout.jsx" \
  "src/app/page.js" "src/app/blog/layout.tsx" "src/index.ts" \
  "src/main.rs" "apps/web/main.go"; do
  [[ "$entrypoints" == *"$candidate"* ]] || { printf 'Missing entrypoint candidate: %s\n' "$candidate" >&2; exit 1; }
done
for excluded in node_modules dist build .git generated; do
  [[ "$entrypoints" != *"$excluded/"* ]] || { printf 'Excluded entrypoint reported: %s\n' "$excluded" >&2; exit 1; }
done
mkdir -p "$fixture/app router only/src/app/(marketing)"
printf 'page\n' > "$fixture/app router only/src/app/(marketing)/page.tsx"
printf 'layout\n' > "$fixture/app router only/src/app/layout.tsx"
entrypoints="$(bash "$skill/scripts/find-entrypoints.sh" "$fixture/app router only")"
[[ "$entrypoints" == *"src/app/(marketing)/page.tsx"* && "$entrypoints" == *"src/app/layout.tsx"* ]] || exit 1

mkdir -p "$fixture/many routes/app"
for ((n=1; n<=82; n++)); do
  mkdir -p "$fixture/many routes/app/route-$n"
  printf 'page\n' > "$fixture/many routes/app/route-$n/page.tsx"
done
entrypoints="$(bash "$skill/scripts/find-entrypoints.sh" "$fixture/many routes")"
[[ "$(printf '%s\n' "$entrypoints" | wc -l | tr -d ' ')" -eq 81 && "$entrypoints" == *'2 additional candidates omitted'* ]] || exit 1

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
printf 'Catch-up shell scenarios passed.\n'
