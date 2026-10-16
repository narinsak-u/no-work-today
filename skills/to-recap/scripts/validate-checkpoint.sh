#!/usr/bin/env bash
set -euo pipefail

# Usage: validate-checkpoint.sh REPOSITORY RECAP [EXPECTED_HEAD]
# This validator never modifies the recap, its repository, or Git history.
if (( $# < 2 || $# > 3 )); then
  echo 'usage: validate-checkpoint.sh REPOSITORY RECAP [EXPECTED_HEAD]' >&2; exit 2
fi
repo=$1
recap=$2
expected_head=${3:-}
fail() { echo "unsafe recap checkpoint: $*" >&2; exit 1; }
[[ -f $recap ]] || fail 'recap does not exist'
git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail 'not a Git worktree'
[[ $(git -C "$repo" rev-parse --is-shallow-repository) == false ]] || fail 'shallow history'
branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD) || fail 'detached HEAD'
head=$(git -C "$repo" rev-parse --verify HEAD^{commit} 2>/dev/null) || {
  git -C "$repo" show-ref --verify --quiet "refs/heads/$branch" &&
    fail 'invalid HEAD commit'
  [[ -z $(git -C "$repo" rev-list --all --max-count=1) ]] ||
    fail 'unborn branch with existing history'
  head=none
}
[[ -z $expected_head || $expected_head == "$head" ]] || fail 'HEAD changed'
# Require one final, well-formed state block and its fingerprint immediately
# before the closing delimiter. Do not normalize any of the hashed bytes.
awk '
  {sub(/\r$/, "")}
  /^<!-- recap-state$/ {opens++; inside=1; next}
  /^-->$/ && inside {closes++; inside=0; next}
  /^output_sha256:/ {hashes++; if (!inside) invalid=1; if ($0 !~ /^output_sha256: [0-9a-f]+$/ || length($0)!=79) invalid=1}
  {if (inside && /^branch: /) branches++; if (inside && /^last_commit: /) commits++; if (inside && /^last_updated: /) dates++; if (inside && /^history_head: /) histories++; if (inside && /^pending_commits: /) queues++}
  END {if (opens!=1 || closes!=1 || inside || hashes!=1 || branches!=1 || commits!=1 || dates!=1 || histories!=queues || histories>1 || invalid) exit 1}
' "$recap" || fail 'malformed or duplicate state fields'
[[ $(awk '{sub(/\r$/, "")} NF {last=$0} END {print last}' "$recap") == '-->' ]] || fail 'state is not final'
[[ $(awk '{sub(/\r$/, "")} /^-->$/ {print previous} {previous=$0}' "$recap") =~ ^output_sha256:\ [0-9a-f]{64}$ ]] || fail 'fingerprint is not immediately before state end'
stored=$(awk '{sub(/\r$/, "")} /^output_sha256: / {print $2}' "$recap")
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sed '/^output_sha256: /d' "$recap" | sha256sum | awk '{print $1}')
else
  actual=$(sed '/^output_sha256: /d' "$recap" | shasum -a 256 | awk '{print $1}')
fi
[[ $actual == "$stored" ]] || fail 'fingerprint mismatch; preserve user edits'
saved_branch=$(awk '/^branch: / {sub(/\r$/, ""); print substr($0,9)}' "$recap")
[[ $saved_branch == "$branch" ]] || fail 'branch mismatch; preserve existing entries'
checkpoint=$(awk '/^last_commit: / {sub(/\r$/, ""); print $2}' "$recap")
if [[ $head == none ]]; then
  [[ $checkpoint == none ]] || fail 'empty history cannot have a recap checkpoint'
  [[ $(awk '/^history_head: / {n++} END {print n+0}' "$recap") == 1 &&
     $(awk '/^history_head: / {print $2}' "$recap") == none &&
     $(awk '/^pending_commits: / {print $2}' "$recap") == none ]] ||
    fail 'empty history requires no history head or pending commits'
  printf 'branch: %s\nhead: none\ncheckpoint: none\n' "$branch"
  exit 0
fi
[[ $checkpoint =~ ^[0-9a-f]{40,64}$ ]] || fail 'invalid checkpoint ID'
[[ $(git -C "$repo" rev-parse --verify "$checkpoint^{commit}" 2>/dev/null || :) == "$checkpoint" ]] || fail 'checkpoint missing or rewritten'
git -C "$repo" merge-base --is-ancestor "$checkpoint" "$head" || fail 'checkpoint not an ancestor of HEAD'
if (( $(awk '/^history_head: / {n++} END {print n+0}' "$recap") )); then
  history_head=$(awk '/^history_head: / {sub(/\r$/, ""); print $2}' "$recap")
  [[ $history_head =~ ^[0-9a-f]{40,64}$ ]] || fail 'invalid history head'
  [[ $(git -C "$repo" rev-parse --verify "$history_head^{commit}" 2>/dev/null || :) == "$history_head" ]] || fail 'history head missing'
  git -C "$repo" merge-base --is-ancestor "$history_head" "$head" || fail 'history head not an ancestor'
  pending=$(awk '/^pending_commits: / {sub(/\r$/, ""); print substr($0,18)}' "$recap")
  [[ $pending == none || $pending =~ ^[0-9a-f]{40,64}(\ [0-9a-f]{40,64})*$ ]] || fail 'malformed pending queue'
  if [[ $pending != none ]]; then
    seen=' '
    for commit in $pending; do
      [[ $seen != *" $commit "* ]] || fail 'duplicate pending commit'
      seen+="$commit "
      [[ $(git -C "$repo" rev-parse --verify "$commit^{commit}" 2>/dev/null || :) == "$commit" ]] || fail 'pending commit missing'
      git -C "$repo" merge-base --is-ancestor "$commit" "$history_head" || fail 'pending commit outside history head'
    done
  fi
fi
printf 'branch: %s\nhead: %s\ncheckpoint: %s\n' "$branch" "$head" "$checkpoint"
