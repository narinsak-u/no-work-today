#!/usr/bin/env bash
set -euo pipefail

# Usage: collect-git-context.sh REPOSITORY [CHECKPOINT [OFFSET [EXPECTED_HEAD]]]
# Without a checkpoint, only the latest 100 commits belong to the initial scope.
# With a checkpoint, paginate the entire checkpoint..HEAD range (100 IDs per call).
if (( $# < 1 || $# > 4 )); then
  echo 'usage: collect-git-context.sh REPOSITORY [CHECKPOINT [OFFSET [EXPECTED_HEAD]]]' >&2
  exit 2
fi
repo=$1
checkpoint=${2:-}
offset=${3:-0}
expected_head=${4:-}
if [[ ! $offset =~ ^(0|[1-9][0-9]*)$ ]]; then
  echo 'offset must be a nonnegative integer' >&2; exit 2
fi
if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo 'not a Git worktree' >&2; exit 1
fi
if [[ $(git -C "$repo" rev-parse --is-shallow-repository) == true ]]; then
  echo 'shallow history: cannot verify the boundary' >&2; exit 1
fi
branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD) || {
  echo 'detached HEAD or unborn branch' >&2; exit 1;
}
head=$(git -C "$repo" rev-parse --verify HEAD^{commit} 2>/dev/null) || {
  echo 'empty repository: no commits' >&2; exit 1;
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
if (( offset > total )); then
  echo 'offset exceeds selected range' >&2; exit 2
fi
end=$((offset + 100))
if ((end > total)); then end=$total; fi
printf 'mode: %s\nbranch: %s\nhead: %s\ncoverage_oldest: %s\nolder_history: %s\ntotal: %s\noffset: %s\nnext_offset: %s\n' \
  "$mode" "$branch" "$head" "$oldest" "$older_history" "$total" "$offset" "$end"
if ((end < total)); then printf 'has_more: yes\n'; else printf 'has_more: no\n'; fi
if [[ $mode == resume ]]; then
  # Git enumerates newest-first. Skip the newer suffix, then reverse only
  # this bounded page; --reverse --skip=OFFSET would skip the wrong end.
  git -C "$repo" rev-list --topo-order --skip="$((total-end))" --max-count="$((end-offset))" "$checkpoint..$head" |
    awk 'NF {commits[++n]=$0} END {for (i=n; i>0; i--) print "commit: " commits[i]}'
else
  # Reverse only the selected latest 100, not the repository's entire history.
  git -C "$repo" rev-list --topo-order --max-count=100 "$head" | awk -v offset="$offset" 'NF {commits[++n]=$0} END {for (i=n-offset; i>n-offset-100 && i>0; i--) print "commit: " commits[i]}'
fi
