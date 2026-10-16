#!/usr/bin/env bash
set -euo pipefail

source_root="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/legacy recap.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
repo="$fixture/project with spaces"
skill="$fixture/agent skills/to-recap"
mkdir -p "$repo/docs" "$fixture/agent skills"
# An installed copy, not source-tree-relative helpers, must be sufficient.
cp -R "$source_root/skills/to-recap" "$skill"
git -C "$repo" init -q
git -C "$repo" config user.email recap@example.test
git -C "$repo" config user.name Recap
git -C "$repo" commit --allow-empty -qm 'older completed work'
base="$(git -C "$repo" rev-parse HEAD)"
branch="$(git -C "$repo" branch --show-current)"
legacy="$repo/docs/recap.md"
cat > "$legacy" <<DOC
# Project Recap

## Scope

- **Committed range:** Earlier work through $base.

## 2025-03-04 — Keep the original dated story

Old-style entry deliberately has no Category, Status or collapsed technical fields.
  Retain these spaces and punctuation verbatim: [old, completed work]!
- Earlier work: \`$base\`.

## Current Point

- **HEAD:** \`$base\` on \`$branch\`
- **Recap checkpoint:** \`$base\`
- **Pending committed history:** None
- **Committed work:** See the older entry.
- **Uncommitted work:** None.
- **Next safe point:** Review commits after this checkpoint.

<!-- recap-state
last_commit: $base
last_updated: 2025-03-04
-->
DOC
git -C "$repo" add docs/recap.md
git -C "$repo" commit -qm 'track legacy recap'
tracked="$(git -C "$repo" rev-parse HEAD)"
printf 'user-facing improvement\n' > "$repo/new-work.txt"
git -C "$repo" add new-work.txt
git -C "$repo" commit -qm 'finish new work'
head="$(git -C "$repo" rev-parse HEAD)"
selected="$fixture/selected"
git -C "$repo" rev-list --topo-order --reverse "$base..$head" > "$selected"
[[ "$(awk 'END {print NR}' "$selected")" == 2 ]] || exit 1
bash "$skill/scripts/validate-legacy-recap.sh" "$repo" "$legacy" "$head"

# The new entry follows today's readable format; the historical entry does not
# have to be recast into that format. Simulate the agent's draft on a separate path.
unsigned="$fixture/draft-unsigned"
awk '/^## Current Point$/ {exit} {print}' "$legacy" > "$unsigned"
legacy_prefix_hash="$(sed '/^## Current Point/,$d' "$legacy" | (sha256sum 2>/dev/null || shasum -a 256) | awk '{print $1}')"
legacy_entry_count="$(awk '/^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] / {n++} END {print n+0}' "$legacy")"
cat >> "$unsigned" <<DOC
## 2026-10-16 — Deliver the new work

- **Category:** features
- **Status:** Completed
- **What / why:** The repository now has a tracked starting point and a user-facing improvement.
- **Impact:** The new work is present in the project.

<details>
<summary>Technical details and commit evidence</summary>

- **Important files:**
  - \`docs/recap.md\` — the earlier recap became tracked.
  - \`new-work.txt\` — the new improvement.
- **Commits:** \`$tracked\` — track the recap; \`$head\` — finish new work.
- **Verification:** not run

</details>

## Current Point

- **HEAD:** \`$head\` on \`$branch\`
- **Recap checkpoint:** \`$head\`
- **Pending committed history:** None
- **Committed work:** The new entry documents both new commits; earlier work is unchanged.
- **Uncommitted work:** The recap publication is not committed yet.
- **Verification:** not run
- **Next safe point:** Inspect the next commit when one appears.

<!-- recap-state
branch: $branch
last_commit: $head
last_updated: 2026-10-16
history_head: $head
pending_commits: none
legacy_prefix: $legacy_entry_count $legacy_prefix_hash
-->
DOC
draft="$fixture/draft"
hash="$( (sha256sum "$unsigned" 2>/dev/null || shasum -a 256 "$unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$hash" '/^-->$/ {print "output_sha256: " hash} {print}' "$unsigned" > "$draft"
prior_prefix="$fixture/prior-prefix"
draft_prefix="$fixture/draft-prefix"
awk '/^## Current Point$/ {exit} {print}' "$legacy" > "$prior_prefix"
awk '/^## 2026-10-16 / {exit} {print}' "$draft" > "$draft_prefix"
cmp "$prior_prefix" "$draft_prefix"
bash "$skill/scripts/validate-recap.sh" "$repo" "$draft" "$selected" "$head" "$legacy"
awk '/^  Retain/ {sub(/verbatim/, "rewritten")} {print}' "$unsigned" > "$fixture/rewritten-unsigned"
rewritten_hash="$( (sha256sum "$fixture/rewritten-unsigned" 2>/dev/null || shasum -a 256 "$fixture/rewritten-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$rewritten_hash" '/^-->$/ {print "output_sha256: " hash} {print}' \
  "$fixture/rewritten-unsigned" > "$fixture/rewritten"
if bash "$skill/scripts/validate-recap.sh" "$repo" "$fixture/rewritten" "$selected" "$head" "$legacy" >/dev/null 2>&1; then
  echo 'An adopted recap rewrote historical entries' >&2; exit 1
fi
awk '!/^- \*\*Status:\*\* /' "$unsigned" > "$fixture/invalid-new-entry-unsigned"
invalid_hash="$( (sha256sum "$fixture/invalid-new-entry-unsigned" 2>/dev/null || shasum -a 256 "$fixture/invalid-new-entry-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$invalid_hash" '/^-->$/ {print "output_sha256: " hash} {print}' \
  "$fixture/invalid-new-entry-unsigned" > "$fixture/invalid-new-entry"
if bash "$skill/scripts/validate-recap.sh" "$repo" "$fixture/invalid-new-entry" "$selected" "$head" "$legacy" >/dev/null 2>&1; then
  echo 'An adopted recap accepted a malformed new entry' >&2; exit 1
fi
awk -v checkpoint="$tracked" '
  /^- \*\*Recap checkpoint:\*\*/ {sub(/`[^`]+`/, "`" checkpoint "`")}
  /^last_commit: / {$0="last_commit: " checkpoint}
  {print}
' "$unsigned" > "$fixture/early-checkpoint-unsigned"
early_hash="$( (sha256sum "$fixture/early-checkpoint-unsigned" 2>/dev/null || shasum -a 256 "$fixture/early-checkpoint-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$early_hash" '/^-->$/ {print "output_sha256: " hash} {print}' \
  "$fixture/early-checkpoint-unsigned" > "$fixture/early-checkpoint"
if bash "$skill/scripts/validate-recap.sh" "$repo" "$fixture/early-checkpoint" "$selected" "$head" "$legacy" >/dev/null 2>&1; then
  echo 'A recap advanced its checkpoint past the represented commits' >&2; exit 1
fi
[[ "$(git -C "$repo" status --short -- docs/recap.md)" == '' ]] || exit 1
cp "$draft" "$legacy"
bash "$skill/scripts/validate-recap.sh" "$repo" "$legacy"
repeat="$(bash "$skill/scripts/collect-git-context.sh" "$repo" "$head" 0 "$head")"
[[ "$repeat" == *'total: 0'* && "$repeat" != *'commit: '* ]] || exit 1
[[ "$(awk '/^## 2026-10-16 / {n++} END {print n+0}' "$legacy")" == 1 ]] || exit 1

# A legacy source must remain untouched when it cannot be safely adopted.
git -C "$repo" show "$tracked:docs/recap.md" > "$legacy"
printf 'local note\n' >> "$legacy"
unsafe_before="$(git -C "$repo" hash-object "$legacy")"
if bash "$skill/scripts/validate-legacy-recap.sh" "$repo" "$legacy" "$head" >/dev/null 2>&1 ||
   bash "$skill/scripts/validate-recap.sh" "$repo" "$draft" "$selected" "$head" "$legacy" >/dev/null 2>&1; then
  echo 'A modified legacy recap was accepted' >&2; exit 1
fi
[[ "$(git -C "$repo" hash-object "$legacy")" == "$unsafe_before" ]] || exit 1
git -C "$repo" add docs/recap.md
if bash "$skill/scripts/validate-legacy-recap.sh" "$repo" "$legacy" "$head" >/dev/null 2>&1; then
  echo 'A staged legacy recap was accepted' >&2; exit 1
fi
[[ "$(git -C "$repo" hash-object "$legacy")" == "$unsafe_before" ]] || exit 1

ambiguous="$fixture/ambiguous project"
git clone -q "$repo" "$ambiguous"
git -C "$ambiguous" config user.email recap@example.test
git -C "$ambiguous" config user.name Recap
awk -v base="$base" '/^last_updated: / {print "last_commit: " base} {print}' \
  "$ambiguous/docs/recap.md" > "$fixture/ambiguous-doc"
cp "$fixture/ambiguous-doc" "$ambiguous/docs/recap.md"
git -C "$ambiguous" add docs/recap.md
git -C "$ambiguous" commit -qm 'ambiguous duplicate checkpoint'
ambiguous_before="$(git -C "$ambiguous" hash-object docs/recap.md)"
if error="$(bash "$skill/scripts/validate-legacy-recap.sh" "$ambiguous" "$ambiguous/docs/recap.md" 2>&1)"; then
  echo 'An ambiguous legacy recap was accepted' >&2; exit 1
fi
[[ "$error" == *'ambiguous'* && "$(git -C "$ambiguous" hash-object docs/recap.md)" == "$ambiguous_before" ]] || exit 1
printf 'Legacy recap append scenarios passed.\n'
