#!/usr/bin/env bash
set -euo pipefail

# Usage: collect-git-context.sh REPOSITORY [CHECKPOINT [0 [EXPECTED_HEAD]]]
# Each invocation returns at most 100 commits; continuation starts at the
# checkpoint published for the previous batch.
if (( $# < 1 || $# > 4 )); then
  echo 'usage: collect-git-context.sh REPOSITORY [CHECKPOINT [0 [EXPECTED_HEAD]]]' >&2
  exit 2
fi
repo=$1
checkpoint=${2:-}
offset=${3:-0}
expected_head=${4:-}
if [[ $offset != 0 ]]; then
  echo 'offset must be 0; continue by publishing the previous batch checkpoint' >&2
  exit 2
fi
if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo 'not a Git worktree' >&2; exit 1
fi
if [[ $(git -C "$repo" rev-parse --is-shallow-repository) == true ]]; then
  echo 'shallow history: cannot verify the boundary' >&2; exit 1
fi
branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD) || {
  echo 'detached HEAD' >&2; exit 1;
}
head=$(git -C "$repo" rev-parse --verify HEAD^{commit} 2>/dev/null) || {
  if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch" ||
     [[ -n $(git -C "$repo" rev-list --all --max-count=1) ]]; then
    echo 'unborn branch with existing or unsafe history; preserve the recap' >&2; exit 1
  fi
  if [[ -n $checkpoint || ( -n $expected_head && $expected_head != none ) ]]; then
    echo 'no commits: checkpoint or expected HEAD cannot be a commit' >&2; exit 1
  fi
  printf 'mode: empty\nbranch: %s\nhead: none\ncoverage_oldest: none\nolder_history: no\ntotal: 0\noffset: 0\nnext_offset: 0\nhas_more: no\n' "$branch"
  exit 0
}
if [[ -n $expected_head && $head != "$expected_head" ]]; then
  echo 'HEAD changed during collection; discard the candidate recap' >&2; exit 1
fi
if [[ -n $checkpoint ]]; then
  if [[ ! $checkpoint =~ ^[0-9a-f]{40,64}$ ]] ||
     [[ $(git -C "$repo" rev-parse --verify "$checkpoint^{commit}" 2>/dev/null || :) != "$checkpoint" ]] ||
     ! git -C "$repo" merge-base --is-ancestor "$checkpoint" "$head"; then
    echo 'missing, invalid, or non-ancestor checkpoint; preserve the recap' >&2; exit 1
  fi
  total=$(git -C "$repo" rev-list --count "$checkpoint..$head")
  mode=resume
  oldest=$checkpoint
  older_history=not-applicable
else
  total=$(git -C "$repo" rev-list --count --max-count=100 "$head")
  mode=initial
  oldest=$(git -C "$repo" rev-list --topo-order --max-count=100 "$head" | awk 'END {print}')
  if (( $(git -C "$repo" rev-list --count --max-count=101 "$head") > 100 )); then
    older_history=yes
  else
    older_history=no
  fi
fi
end=100
if ((end > total)); then end=$total; fi
printf 'mode: %s\nbranch: %s\nhead: %s\ncoverage_oldest: %s\nolder_history: %s\ntotal: %s\noffset: 0\nnext_offset: %s\n' \
  "$mode" "$branch" "$head" "$oldest" "$older_history" "$total" "$end"
if ((end < total)); then printf 'has_more: yes\n'; else printf 'has_more: no\n'; fi
if [[ $mode == resume ]]; then
  git -C "$repo" rev-list --topo-order --skip="$((total-end))" --max-count="$end" "$checkpoint..$head" |
    awk 'NF {commits[++n]=$0} END {for (i=n; i>0; i--) print "commit: " commits[i]}'
else
  git -C "$repo" rev-list --topo-order --max-count=100 "$head" |
    awk 'NF {commits[++n]=$0} END {for (i=n; i>0; i--) print "commit: " commits[i]}'
fi
