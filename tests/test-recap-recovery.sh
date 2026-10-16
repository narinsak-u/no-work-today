#!/usr/bin/env bash
set -euo pipefail

skill="$(cd "$(dirname "$0")/../skills/to-recap" && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/recap recovery.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
repo="$fixture/project with spaces"
mkdir -p "$repo/docs"
git -C "$repo" init -q
git -C "$repo" config user.email recap@example.test
git -C "$repo" config user.name Recap

git -C "$repo" commit --allow-empty -qm 'shared foundation'
anchor="$(git -C "$repo" rev-parse HEAD)"
git -C "$repo" commit --allow-empty -qm 'old work, later rewritten'
old="$(git -C "$repo" rev-parse HEAD)"
branch="$(git -C "$repo" branch --show-current)"

sign() {
  local unsigned=$1 signed=$2 digest
  digest="$( (sha256sum "$unsigned" 2>/dev/null || shasum -a 256 "$unsigned") | awk 'NR==1 {print $1}')"
  awk -v hash="$digest" '/^-->$/ {print "output_sha256: " hash} {print}' "$unsigned" > "$signed"
}

# Prior completed history has a documented shared ancestor and a now-orphaned
# checkpoint. The orphaned work must remain in historical entries, not be
# silently conflated with the new commits after the rewrite.
cat > "$fixture/prior-unsigned" <<DOC
# Project Recap
## Scope
- **Committed range:** $anchor through $old inclusive.
## 2026-10-10 — Earlier completed work
- **Category:** testing
- **Status:** Completed
- **What / why:** Captured the first two commits.
<details>
<summary>Technical details and commit evidence</summary>
- **Important files:** none
- **Commits:** \`$anchor\` — shared foundation; \`$old\` — replaced history
- **Verification:** not run
</details>
- **Impact:** History documented.
## Current Point
- **HEAD:** \`$old\` on \`$branch\`
- **Recap checkpoint:** \`$old\`
- **Pending committed history:** None
- **Committed work:** First two commits documented.
- **Uncommitted work:** None.
- **Verification:** not run
- **Next safe point:** None identified.
<!-- recap-state
branch: $branch
last_commit: $old
last_updated: 2026-10-10
history_head: $old
pending_commits: none
-->
DOC
recap="$repo/docs/recap.md"
sign "$fixture/prior-unsigned" "$recap"
cp "$recap" "$fixture/prior-signed"
git -C "$repo" add docs/recap.md
git -C "$repo" commit -qm 'publish original recap'
original_head="$(git -C "$repo" rev-parse HEAD)"
# Rewrite the branch from the last represented ancestor, excluding the old
# checkpoint (and the old recap commit) while retaining the published document.
git -C "$repo" checkout -qb replacement "$anchor"
git -C "$repo" commit --allow-empty -qm 'new work after rewrite'
replacement_first="$(git -C "$repo" rev-parse HEAD)"
git -C "$repo" commit --allow-empty -qm 'follow-up after rewrite'
replacement_last="$(git -C "$repo" rev-parse HEAD)"
git -C "$repo" update-ref "refs/heads/$branch" "$replacement_last" "$original_head"
git -C "$repo" checkout -q "$branch"
mkdir -p "$repo/docs"
cp "$fixture/prior-signed" "$recap"

[[ "$(bash "$skill/scripts/validate-checkpoint.sh" "$repo" "$recap" "$replacement_last" --recover)" == *"recovery_boundary: $anchor"* ]] || {
  echo 'Documented rewrite boundary was not recovered' >&2; exit 1;
}
if bash "$skill/scripts/validate-checkpoint.sh" "$repo" "$recap" "$replacement_last" >/dev/null 2>&1; then
  echo 'Normal checkpoint validation accepted rewritten history' >&2; exit 1
fi
printf '%s\n' "$replacement_first" "$replacement_last" > "$fixture/selected"
cat > "$fixture/draft-unsigned" <<DOC
# Project Recap
## Scope
- **Committed range:** $anchor through $old inclusive.
## 2026-10-10 — Earlier completed work
- **Category:** testing
- **Status:** Completed
- **What / why:** Captured the first two commits.
<details>
<summary>Technical details and commit evidence</summary>
- **Important files:** none
- **Commits:** \`$anchor\` — shared foundation; \`$old\` — replaced history
- **Verification:** not run
</details>
- **Impact:** History documented.
## 2026-10-11 — New history after rewrite
- **Category:** testing
- **Status:** Completed
- **What / why:** Captured only new commits after the documented shared boundary; the old checkpoint is now outside the current graph.
<details>
<summary>Technical details and commit evidence</summary>
- **Important files:** none
- **Commits:** \`$replacement_first\` — new work; \`$replacement_last\` — follow-up
- **Verification:** not run
</details>
- **Impact:** Rewritten branch history documented without altering old work.
## Current Point
- **HEAD:** \`$replacement_last\` on \`$branch\`
- **Recap checkpoint:** \`$replacement_last\`
- **Pending committed history:** None
- **Committed work:** New history recorded; previously documented orphaned work is historical, not current-branch work.
- **Uncommitted work:** None.
- **Verification:** not run
- **Next safe point:** None identified.
<!-- recap-state
branch: $branch
last_commit: $replacement_last
last_updated: 2026-10-11
history_head: $replacement_last
pending_commits: none
-->
DOC
sign "$fixture/draft-unsigned" "$fixture/draft"
bash "$skill/scripts/validate-recap.sh" "$repo" "$fixture/draft" "$fixture/selected" "$replacement_last" "$recap" >/dev/null
cmp -s <(sed '/^## Current Point/,$d' "$recap") <(sed '/^## Current Point/,$d' "$fixture/draft") || {
  echo 'Recovery did not preserve prior entries' >&2; exit 1;
}
printf '%s\n' "$replacement_last" > "$fixture/skipped"
if bash "$skill/scripts/validate-recap.sh" "$repo" "$fixture/draft" "$fixture/skipped" "$replacement_last" "$recap" >/dev/null 2>&1; then
  echo 'Recovery omitted a new commit without rejection' >&2; exit 1
fi

# A documented ancestor is indispensable: if the only recorded entry is the
# orphaned checkpoint, there is no evidence of an already represented boundary.
awk -v old="$old" '
  /^- \*\*Commits:/ {print "- **Commits:** `" old "` — replaced history"; next}
  /^output_sha256: / {next}
  {print}
' "$fixture/prior-unsigned" > "$fixture/no-boundary-unsigned"
sign "$fixture/no-boundary-unsigned" "$fixture/no-boundary"
# A valid fingerprint alone must not authorize choosing an arbitrary merge-base.
for unsafe in no-boundary missing-checkpoint old-pending tampered; do
  case "$unsafe" in
    missing-checkpoint)
      awk '/^last_commit: / {print "last_commit: 0000000000000000000000000000000000000000"; next} {print}' "$fixture/prior-unsigned" > "$fixture/$unsafe-unsigned"
      sign "$fixture/$unsafe-unsigned" "$fixture/$unsafe" ;;
    old-pending)
      awk -v old="$old" '/^pending_commits: / {print "pending_commits: " old; next} {print}' "$fixture/prior-unsigned" > "$fixture/$unsafe-unsigned"
      sign "$fixture/$unsafe-unsigned" "$fixture/$unsafe" ;;
    tampered)
      cp "$fixture/no-boundary" "$fixture/$unsafe"
      printf 'unsigned edit\n' >> "$fixture/$unsafe" ;;
  esac
  cp "$fixture/$unsafe" "$recap"
  before="$(git -C "$repo" hash-object "$recap")"
  if bash "$skill/scripts/validate-checkpoint.sh" "$repo" "$recap" "$replacement_last" --recover > "$fixture/result" 2>&1; then
    echo "Unsafe $unsafe source was allowed to recover" >&2; exit 1
  fi
  [[ -s "$fixture/result" ]] || { echo "Unsafe $unsafe recovery gave no reason" >&2; exit 1; }
  if bash "$skill/scripts/validate-recap.sh" "$repo" "$fixture/draft" "$fixture/selected" "$replacement_last" "$recap" > "$fixture/result" 2>&1; then
    echo "Unsafe $unsafe source allowed partial publication" >&2; exit 1
  fi
  [[ -s "$fixture/result" && "$(git -C "$repo" hash-object "$recap")" == "$before" ]] || {
    echo "Unsafe $unsafe recovery changed published recap or gave no reason" >&2; exit 1;
  }
done
cp "$fixture/prior-signed" "$recap"
if ! bash "$skill/scripts/validate-recap.sh" "$repo" "$fixture/draft" "$fixture/selected" "$replacement_last" "$recap" >/dev/null; then
  echo 'Previously safe recovery no longer validates' >&2; exit 1
fi
# A publication is permitted only after validation. The published recap must
# remain valid on the current graph with each new commit represented once.
cp "$fixture/draft" "$repo/docs/recap.md"
bash "$skill/scripts/validate-recap.sh" "$repo" "$recap" >/dev/null
[[ "$(awk -v first="$replacement_first" -v last="$replacement_last" '/^- \*\*Commits:/ {if (index($0,first)) a++; if (index($0,last)) b++} END {print a+0, b+0}' "$recap")" == '1 1' ]] || {
  echo 'New commits missing or repeated' >&2; exit 1;
}
# Two incomparable merge bases cannot establish a single continuation point.
ambiguous_repo="$fixture/ambiguous history"
mkdir -p "$ambiguous_repo/docs"
git -C "$ambiguous_repo" init -q
git -C "$ambiguous_repo" config user.email recap@example.test
git -C "$ambiguous_repo" config user.name Recap
git -C "$ambiguous_repo" commit --allow-empty -qm foundation
shared="$(git -C "$ambiguous_repo" rev-parse HEAD)"
git -C "$ambiguous_repo" checkout -qb left
git -C "$ambiguous_repo" commit --allow-empty -qm left
left="$(git -C "$ambiguous_repo" rev-parse HEAD)"
git -C "$ambiguous_repo" checkout -qb right "$shared"
git -C "$ambiguous_repo" commit --allow-empty -qm right
right="$(git -C "$ambiguous_repo" rev-parse HEAD)"
tree="$(git -C "$ambiguous_repo" rev-parse HEAD^{tree})"
old_merge="$(git -C "$ambiguous_repo" commit-tree "$tree" -p "$left" -p "$right" -m 'previous merge')"
new_merge="$(git -C "$ambiguous_repo" commit-tree "$tree" -p "$right" -p "$left" -m 'rewritten merge')"
git -C "$ambiguous_repo" update-ref refs/heads/right "$old_merge" "$right"
cat > "$fixture/ambiguous-unsigned" <<DOC
# Project Recap
## Scope
- **Committed range:** through $old_merge.
## 2026-10-10 — Previously merged work
- **Category:** testing
- **Status:** Completed
- **What / why:** Recorded both sides of a merge.
<details>
<summary>Technical details and commit evidence</summary>
- **Important files:** none
- **Commits:** \`$shared\` — base; \`$left\` — left; \`$right\` — right; \`$old_merge\` — merge
- **Verification:** not run
</details>
- **Impact:** Both branches represented.
## Current Point
- **HEAD:** \`$old_merge\` on \`right\`
- **Recap checkpoint:** \`$old_merge\`
- **Pending committed history:** None
- **Committed work:** Merged branches recorded.
- **Uncommitted work:** None.
- **Verification:** not run
- **Next safe point:** None identified.
<!-- recap-state
branch: right
last_commit: $old_merge
last_updated: 2026-10-10
history_head: $old_merge
pending_commits: none
-->
DOC
sign "$fixture/ambiguous-unsigned" "$ambiguous_repo/docs/recap.md"
git -C "$ambiguous_repo" update-ref refs/heads/right "$new_merge" "$old_merge"
ambiguous_before="$(git -C "$ambiguous_repo" hash-object "$ambiguous_repo/docs/recap.md")"
if bash "$skill/scripts/validate-checkpoint.sh" "$ambiguous_repo" "$ambiguous_repo/docs/recap.md" "$new_merge" --recover > "$fixture/result" 2>&1; then
  echo 'Two merge bases were mistaken for a safe boundary' >&2; exit 1
fi
[[ "$(cat "$fixture/result")" == *'no unique common ancestor'* &&
  "$(git -C "$ambiguous_repo" hash-object "$ambiguous_repo/docs/recap.md")" == "$ambiguous_before" ]] || {
  echo 'Ambiguous merge did not stop unchanged with a reason' >&2; exit 1;
}
printf 'Stale recap recovery scenarios passed.\n'
