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

# Install each skill into its own isolated agent directory, then exercise its
# installed shell helpers without relying on sibling skills.
for skill in to-catchup to-recap to-backlog; do
  mkdir -p "$fixture/agent-$skill"
  cp -R "$source_root/skills/$skill" "$fixture/agent-$skill/"
done
catchup="$fixture/agent-to-catchup/to-catchup"
recap="$fixture/agent-to-recap/to-recap"
backlog="$fixture/agent-to-backlog/to-backlog"
[[ -f "$catchup/SKILL.md" && ! -e "$fixture/agent-to-catchup/to-recap" ]] || exit 1
[[ -f "$recap/SKILL.md" && ! -e "$fixture/agent-to-recap/to-backlog" ]] || exit 1
[[ -f "$backlog/SKILL.md" && ! -e "$fixture/agent-to-backlog/to-catchup" ]] || exit 1
[[ "$(bash "$catchup/scripts/detect-stack.sh" "$project")" == *'apps/web/package.json|Next.js'* ]] || exit 1
[[ "$(bash "$catchup/scripts/detect-stack.sh" "$project")" == *'services/api/go.mod|Go'* ]] || exit 1
[[ "$(bash "$catchup/scripts/find-entrypoints.sh" "$project")" == *'apps/web/src/main.ts'* ]] || exit 1
[[ "$(bash "$recap/scripts/collect-git-context.sh" "$project")" == *'total: 1'* ]] || exit 1
[[ "$(bash "$backlog/scripts/find-todos.sh" "$project")" == *'services/api/handler.go:1:'* ]] || exit 1
cp "$source_root/examples/overview.md" "$project/docs/overview.md"
bash "$catchup/scripts/validate-overview.sh" "$project/docs/overview.md"
rm "$project/docs/overview.md"
[[ ! -e "$project/docs/overview.md" && ! -e "$project/docs/recap.md" && ! -e "$project/docs/backlog.md" ]] || exit 1
printf 'Standalone installation scenarios passed.\n'
