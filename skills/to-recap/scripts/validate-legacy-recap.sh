#!/usr/bin/env bash
set -euo pipefail

# Usage: validate-legacy-recap.sh REPOSITORY TRACKED_RECAP [EXPECTED_HEAD]
# An unsigned legacy document is adoptable only when Git provides unchanged
# ownership and its own current point identifies one reachable boundary.
if (( $# < 2 || $# > 3 )); then
  echo 'usage: validate-legacy-recap.sh REPOSITORY TRACKED_RECAP [EXPECTED_HEAD]' >&2; exit 2
fi
repo=$1
recap=$2
expected_head=${3:-}
fail() { echo "unsafe legacy recap: $*; preserve the existing recap" >&2; exit 1; }
root=$(git -C "$repo" -c core.fsmonitor=false rev-parse --show-toplevel 2>/dev/null) || fail 'not a Git worktree'
[[ $(git -C "$root" -c core.fsmonitor=false rev-parse --is-shallow-repository) == false ]] || fail 'shallow history'
[[ -f $recap && ! -L $recap && $recap -ef "$root/docs/recap.md" ]] || fail 'recap is not docs/recap.md'
git -C "$root" -c core.fsmonitor=false ls-files --error-unmatch docs/recap.md >/dev/null 2>&1 || fail 'recap is not tracked'
[[ -z $(git -C "$root" -c core.fsmonitor=false status --porcelain -- docs/recap.md) ]] || fail 'recap has staged or unstaged changes'
branch=$(git -C "$root" -c core.fsmonitor=false symbolic-ref --quiet --short HEAD) || fail 'detached or unborn HEAD'
head=$(git -C "$root" -c core.fsmonitor=false rev-parse --verify HEAD^{commit} 2>/dev/null) || fail 'no commits'
[[ -z $expected_head || $expected_head == "$head" ]] || fail 'HEAD changed'
# Delimit the state block instead of extracting a coincidental prose hash.
awk '
  {sub(/\r$/, "")}
  /^# Project Recap$/ {title++}
  /^## Scope$/ {scope++}
  /^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] / {entries++}
  /^## Current Point$/ {current++; in_current=1; in_entry=0; next}
  /^## / {in_current=0}
  /^<!-- recap-state$/ {opens++; inside=1; in_current=0; next}
  /^-->$/ {if (inside) closes++; inside=0; next}
  /^(output_sha256|history_head|pending_commits):/ {bad=1}
  inside && /^last_commit:/ {commits++}
  inside && /^last_updated:/ {dates++}
  inside && /^branch:/ {branches++}
  in_current && /^- \*\*HEAD:\*\*/ {heads++}
  in_current && /^- \*\*Recap checkpoint:\*\*/ {points++}
  END {if (title!=1 || scope!=1 || entries<1 || current!=1 || opens!=1 || closes!=1 ||
           inside || commits!=1 || dates!=1 || branches>1 || heads!=1 || points!=1 || bad) exit 1}
' "$recap" || fail 'ambiguous or malformed legacy checkpoint/state'
[[ $(awk 'NF {last=$0} END {sub(/\r$/, "", last); print last}' "$recap") == '-->' ]] || fail 'legacy state is not final'
checkpoint=$(awk '/^last_commit: / {sub(/\r$/, ""); print $2}' "$recap")
[[ $checkpoint =~ ^[0-9a-f]{40,64}$ ]] || fail 'ambiguous or invalid legacy checkpoint'
[[ $(git -C "$root" -c core.fsmonitor=false rev-parse --verify "$checkpoint^{commit}" 2>/dev/null || :) == "$checkpoint" ]] || fail 'legacy checkpoint missing or rewritten'
point=$(awk '/^- \*\*Recap checkpoint:\*\* / {sub(/\r$/, ""); print}' "$recap")
[[ $point == "- **Recap checkpoint:** \`$checkpoint\`" ]] || fail 'ambiguous Current Point checkpoint'
current_head=$(awk '/^- \*\*HEAD:\*\* / {sub(/\r$/, ""); print}' "$recap")
head_pattern='^- \*\*HEAD:\*\* `([0-9a-f]{40,64})` on `([^`]+)`$'
if [[ $current_head =~ $head_pattern ]]; then
  old_head=${BASH_REMATCH[1]}
  old_branch=${BASH_REMATCH[2]}
else
  fail 'ambiguous Current Point HEAD or branch'
fi
[[ $old_branch == "$branch" ]] || fail 'legacy branch mismatch'
saved_branch=$(awk '/^branch: / {sub(/\r$/, ""); print substr($0,9)}' "$recap")
[[ -z $saved_branch || $saved_branch == "$branch" ]] || fail 'legacy state branch mismatch'
[[ $(git -C "$root" -c core.fsmonitor=false rev-parse --verify "$old_head^{commit}" 2>/dev/null || :) == "$old_head" ]] || fail 'legacy Current Point HEAD missing'
git -C "$root" -c core.fsmonitor=false merge-base --is-ancestor "$checkpoint" "$old_head" || fail 'checkpoint outside legacy Current Point'
git -C "$root" -c core.fsmonitor=false merge-base --is-ancestor "$old_head" "$head" || fail 'legacy Current Point not an ancestor of HEAD'
printf 'legacy recap checkpoint: %s\n' "$checkpoint"
