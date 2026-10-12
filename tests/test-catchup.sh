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
  "app/page.tsx" "app/(dashboard)/layout.jsx" "app/(dashboard)/page.ts" \
  "src/app/page.js" "src/app/blog/layout.tsx" "src/app/blog/layout.ts" "src/index.ts"; do
  printf 'candidate\n' > "$fixture/my project/$candidate"
done
for excluded in node_modules dist build .git generated; do
  printf 'skip\n' > "$fixture/my project/$excluded/app/page.tsx"
done
mkdir -p "$fixture/my project/app/(dashboard)/reports/2026/quarter/one" \
  "$fixture/my project/src/app/blog/(archive)/year/month/day" \
  "$fixture/my project/app/_private/(group)" \
  "$fixture/my project/app/(dashboard)/_internal/nested" \
  "$fixture/my project/src/app/blog/_draft/nested" \
  "$fixture/my project/app/reports" \
  "$fixture/my project/apps/web/one/two/three/four"
for candidate in \
  "app/(dashboard)/reports/2026/quarter/one/page.tsx" \
  "src/app/blog/(archive)/year/month/day/layout.jsx"; do
  printf 'candidate\n' > "$fixture/my project/$candidate"
done
for excluded in \
  "app/_private/(group)/page.tsx" \
  "app/(dashboard)/_internal/nested/layout.js" \
  "src/app/blog/_draft/nested/page.jsx" \
  "app/reports/page.md" "app/reports/layout.md" \
  "app/reports/page.test.tsx" "app/reports/layout.test.tsx"; do
  printf 'skip\n' > "$fixture/my project/$excluded"
done
printf 'skip\n' > "$fixture/my project/apps/web/one/two/three/four/main.go"
entrypoints="$(bash "$skill/scripts/find-entrypoints.sh" "$fixture/my project")"
for candidate in \
  "app/page.tsx" "app/(dashboard)/layout.jsx" "app/(dashboard)/page.ts" \
  "src/app/page.js" "src/app/blog/layout.tsx" "src/app/blog/layout.ts" "src/index.ts" \
  "src/main.rs" "apps/web/main.go" \
  "app/(dashboard)/reports/2026/quarter/one/page.tsx" \
  "src/app/blog/(archive)/year/month/day/layout.jsx"; do
  [[ "$entrypoints" == *"$candidate"* ]] || { printf 'Missing entrypoint candidate: %s\n' "$candidate" >&2; exit 1; }
done
for excluded in node_modules dist build .git generated; do
  [[ "$entrypoints" != *"$excluded/"* ]] || { printf 'Excluded entrypoint reported: %s\n' "$excluded" >&2; exit 1; }
done
for excluded in \
  "app/_private/(group)/page.tsx" \
  "app/(dashboard)/_internal/nested/layout.js" \
  "src/app/blog/_draft/nested/page.jsx" \
  "app/reports/page.md" "app/reports/layout.md" \
  "app/reports/page.test.tsx" "app/reports/layout.test.tsx" \
  "apps/web/one/two/three/four/main.go"; do
  [[ "$entrypoints" != *"$excluded"* ]] || { printf 'Invalid entrypoint reported: %s\n' "$excluded" >&2; exit 1; }
done
mkdir -p "$fixture/app router only/src/app/(marketing)"
printf 'page\n' > "$fixture/app router only/src/app/(marketing)/page.ts"
printf 'layout\n' > "$fixture/app router only/src/app/layout.ts"
entrypoints="$(bash "$skill/scripts/find-entrypoints.sh" "$fixture/app router only")"
[[ "$entrypoints" == *"src/app/(marketing)/page.ts"* && "$entrypoints" == *"src/app/layout.ts"* ]] || exit 1

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

# A framework name in scripts, metadata, or an unrelated nested object is not a dependency.
mkdir -p "$fixture/misleading manifest" "$fixture/declared framework"
cat > "$fixture/misleading manifest/package.json" <<'JSON'
{
  "scripts": {"next": "echo next", "start": "echo \"react\": \"18\""},
  "description": "Uses next",
  "metadata": {"dependencies": {"vue": "3.0.0"}},
  "dependencies": {"unrelated": "1.0.0"}
}
JSON
stack="$(bash "$skill/scripts/detect-stack.sh" "$fixture/misleading manifest")"
[[ "$stack" == 'package.json|JavaScript / TypeScript' ]] || { printf 'Non-dependencies produced framework hints: %s\n' "$stack" >&2; exit 1; }
cat > "$fixture/declared framework/package.json" <<'JSON'
{
  "scripts": {"next": "echo next"},
  "devDependencies": {
    "next": "14.0.0",
    "@sveltejs/kit": "2.0.0"
  }
}
JSON
stack="$(bash "$skill/scripts/detect-stack.sh" "$fixture/declared framework")"
[[ "$stack" == *'package.json|Next.js'* && "$stack" == *'package.json|SvelteKit'* ]] || { printf 'Declared frameworks were missed: %s\n' "$stack" >&2; exit 1; }
[[ "$stack" != *'|Svelte' ]] || { printf 'A different framework was inferred: %s\n' "$stack" >&2; exit 1; }

mkdir -p "$fixture/ambiguous rust" "$fixture/declared rust" "$fixture/ambiguous python" "$fixture/declared python"
printf '[package]\nname = "axum"\n[package.metadata]\naxum = "not a dependency"\n' > "$fixture/ambiguous rust/Cargo.toml"
printf '[dependencies]\naxum = "0.8"\n' > "$fixture/declared rust/Cargo.toml"
printf '[project]\ndescription = "fastapi"\ndependencies = [\n  # "fastapi" is not installed\n  "unrelated>=1"\n]\n[tool.other]\nfastapi = "not a dependency"\n' > "$fixture/ambiguous python/pyproject.toml"
printf '# fastapi is not installed\nunrelated==1.0\n' > "$fixture/ambiguous python/requirements.txt"
printf '[project]\ndependencies = ["fastapi>=0.100"]\n' > "$fixture/declared python/pyproject.toml"
printf 'fastapi>=0.100\n' > "$fixture/declared python/requirements.txt"
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/ambiguous rust")" == 'Cargo.toml|Rust' ]] || exit 1
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/declared rust")" == *'Cargo.toml|Axum'* ]] || exit 1
stack="$(bash "$skill/scripts/detect-stack.sh" "$fixture/ambiguous python")"
[[ "$stack" != *'|FastAPI'* && "$stack" == *'pyproject.toml|Python'* && "$stack" == *'requirements.txt|Python'* ]] || exit 1
stack="$(bash "$skill/scripts/detect-stack.sh" "$fixture/declared python")"
[[ "$stack" == *'pyproject.toml|FastAPI'* && "$stack" == *'requirements.txt|FastAPI'* ]] || exit 1
printf '[project.optional-dependencies]\napi = [\n  "fastapi[all]>=0.100",\n]\n' > "$fixture/declared python/pyproject.toml"
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/declared python")" == *'pyproject.toml|FastAPI'* ]] || exit 1

# TOML table indentation and dependency-name case do not change declared evidence.
mkdir -p "$fixture/indented cargo" "$fixture/misleading indented cargo" "$fixture/poetry distribution" "$fixture/misleading poetry"
printf '  [dependencies] # declared crates\naxum = "0.8"\n' > "$fixture/indented cargo/Cargo.toml"
printf '[dependencies]\nother = "1"\n  [package.metadata] # not dependencies\naxum = "not a dependency"\n' > "$fixture/misleading indented cargo/Cargo.toml"
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/indented cargo")" == $'Cargo.toml|Rust\nCargo.toml|Axum' ]] || { printf 'Indented dependency table lost Axum\n' >&2; exit 1; }
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/misleading indented cargo")" == 'Cargo.toml|Rust' ]] || { printf 'Indented non-dependency table produced Axum\n' >&2; exit 1; }
printf '[tool.poetry.group.api.dependencies]\nFastAPI = "^0.100"\n' > "$fixture/poetry distribution/pyproject.toml"
printf '[tool.poetry.scripts]\nFastAPI = "app:main"\n[tool.other.dependencies]\nFastAPI = "^0.100"\n[tool.poetry.dependencies]\n# FastAPI = "^0.100"\n' > "$fixture/misleading poetry/pyproject.toml"
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/poetry distribution")" == $'pyproject.toml|Python\npyproject.toml|FastAPI' ]] || { printf 'Mixed-case Poetry dependency lost FastAPI\n' >&2; exit 1; }
printf '[tool.poetry.dependencies]\nFastAPI = "^0.100"\n' > "$fixture/poetry distribution/pyproject.toml"
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/poetry distribution")" == $'pyproject.toml|Python\npyproject.toml|FastAPI' ]] || { printf 'Mixed-case direct Poetry dependency lost FastAPI\n' >&2; exit 1; }
printf '  [project] # package metadata\n  dependencies = ["FastAPI>=0.100"]\n' > "$fixture/poetry distribution/pyproject.toml"
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/poetry distribution")" == $'pyproject.toml|Python\npyproject.toml|FastAPI' ]] || { printf 'Indented commented project table lost FastAPI\n' >&2; exit 1; }
printf '  [project.optional-dependencies] # extras\napi = ["fastapi>=0.100"]\n' > "$fixture/poetry distribution/pyproject.toml"
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/poetry distribution")" == $'pyproject.toml|Python\npyproject.toml|FastAPI' ]] || { printf 'Indented commented optional project table lost FastAPI\n' >&2; exit 1; }
[[ "$(bash "$skill/scripts/detect-stack.sh" "$fixture/misleading poetry")" == 'pyproject.toml|Python' ]] || { printf 'Non-dependency Poetry keys produced FastAPI\n' >&2; exit 1; }
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
