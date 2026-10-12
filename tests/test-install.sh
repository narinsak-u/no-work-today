#!/usr/bin/env bash
set -euo pipefail

source_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/standalone skills.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/agent skills" "$fixture/project with spaces/apps/web/src" "$fixture/project with spaces/services/api" "$fixture/project with spaces/docs"
project="$fixture/project with spaces"
printf '{"dependencies":{"next":"14.0.0"}}\n' > "$project/apps/web/package.json"
printf 'export default function Home() {}\n' > "$project/apps/web/src/main.ts"
printf 'module example.test/service\n' > "$project/services/api/go.mod"
printf '// TODO: Fix lost requests during retries\n' > "$project/services/api/handler.go"
git -C "$project" init -q
git -C "$project" -c user.email=fixture@example.test -c user.name=Fixture commit --allow-empty -qm initial

# Copy one skill at a time, as a manual single-skill installation would.
for skill in to-catchup to-recap to-backlog; do
  cp -R "$source_root/skills/$skill" "$fixture/agent skills/$skill"
done
[[ "$(bash "$fixture/agent skills/to-catchup/scripts/detect-stack.sh" "$project")" == *'apps/web/package.json|Next.js'* ]] || exit 1
[[ "$(bash "$fixture/agent skills/to-catchup/scripts/detect-stack.sh" "$project")" == *'services/api/go.mod|Go'* ]] || exit 1
[[ "$(bash "$fixture/agent skills/to-catchup/scripts/find-entrypoints.sh" "$project")" == *'apps/web/src/main.ts'* ]] || exit 1
[[ "$(bash "$fixture/agent skills/to-recap/scripts/collect-git-context.sh" "$project")" == *'total: 1'* ]] || exit 1
[[ "$(bash "$fixture/agent skills/to-backlog/scripts/find-todos.sh" "$project")" == *'services/api/handler.go:1:'* ]] || exit 1
[[ ! -e "$project/docs/overview.md" && ! -e "$project/docs/recap.md" && ! -e "$project/docs/backlog.md" ]] || exit 1
printf 'Standalone installation scenarios passed.\n'
