#!/usr/bin/env bash
set -euo pipefail

# Usage: changed-files.sh REPOSITORY COMMIT [OFFSET [LIMIT]]
# Name/status relative to the first parent; root commits compare to empty tree.
if (( $# < 2 || $# > 4 )); then
  echo 'usage: changed-files.sh REPOSITORY COMMIT [OFFSET [LIMIT]]' >&2; exit 2
fi
repo=$1
commit=$2
offset=${3:-0}
limit=${4:-100}
if [[ ! $offset =~ ^(0|[1-9][0-9]*)$ || ! $limit =~ ^[1-9][0-9]*$ ]] || ((limit > 100)); then
  echo 'offset must be nonnegative and limit must be 1..100' >&2; exit 2
fi
if [[ ! $commit =~ ^[0-9a-f]{40,64}$ ]] ||
   [[ $(git -C "$repo" rev-parse --verify "$commit^{commit}" 2>/dev/null || :) != "$commit" ]]; then
  echo 'commit missing or not a full commit hash' >&2; exit 1
fi
parent=$(git -C "$repo" rev-list --parents -n1 "$commit")
parent=${parent#* }
parent=${parent%% *}
if [[ $parent == "$commit" ]]; then
  # Root commits have no parent.
  command=(git -C "$repo" diff-tree --root --no-commit-id --name-status -r "$commit")
else
  command=(git -C "$repo" diff --name-status "$parent" "$commit")
fi
total=$("${command[@]}" | awk 'END {print NR}')
if ((offset > total)); then echo 'offset exceeds changed-file count' >&2; exit 2; fi
end=$((offset + limit))
if ((end > total)); then end=$total; fi
printf 'commit: %s\ntotal: %s\noffset: %s\nnext_offset: %s\n' "$commit" "$total" "$offset" "$end"
if ((end < total)); then printf 'has_more: yes\n'; else printf 'has_more: no\n'; fi
"${command[@]}" | awk -v start="$offset" -v end="$end" 'NR>start && NR<=end {print "file: " $0}'
