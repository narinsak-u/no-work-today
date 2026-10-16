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
branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD) || fail 'detached or unborn HEAD'
head=$(git -C "$repo" rev-parse --verify HEAD^{commit} 2>/dev/null) || fail 'no commits'
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
[[ $checkpoint =~ ^[0-9a-f]{40,64}$ ]] || fail 'invalid checkpoint ID'
[[ $(git -C "$repo" rev-parse --verify "$checkpoint^{commit}" 2>/dev/null || :) == "$checkpoint" ]] || fail 'checkpoint missing or rewritten'
git -C "$repo" merge-base --is-ancestor "$checkpoint" "$head" || fail 'checkpoint not an ancestor of HEAD'
if (( $(awk '/^history_head: / {n++} END {print n+0}' "$recap") )); then
  history_head=$(awk '/^history_head: / {sub(/\r$/, ""); print $2}' "$recap")
  [[ $history_head =~ ^[0-9a-f]{40,64}$ ]] || fail 'invalid history head'
  [[ $(git -C "$repo" rev-parse --verify "$history_head^{commit}" 2>/dev/null || :) == "$history_head" ]] || fail 'history head missing'
  git -C "$repo" merge-base --is-ancestor "$history_head" "$head" || fail 'history head not an ancestor'
  queue_file=$(mktemp "${TMPDIR:-/tmp}/recap-pending.XXXXXX")
  trap 'rm -f "$queue_file"' EXIT
  # Never pass a document's pending queue through -v or another process
  # argument: a legitimate long history can exceed the OS per-argument limit.
  awk '/^pending_commits: / {print substr($0,18)}' "$recap" | tr ' ' '\n' > "$queue_file"
  awk '
    $0 == "none" && NR == 1 {empty=1; next}
    $0 !~ /^[0-9a-f]+$/ || (length($0)!=40 && length($0)!=64) || seen[$0]++ {bad=1}
    END {if (bad || NR==0 || (empty && NR!=1)) exit 1}
  ' "$queue_file" || fail 'malformed or duplicate pending queue'
  if [[ $(awk 'NR==1 {print; exit}' "$queue_file") != none ]]; then
    # A single walk proves every ID belongs to the pinned history, without
    # spawning Git once per commit or growing a quadratic shell string.
    git -C "$repo" rev-list "$history_head" |
      awk 'NR==FNR {reachable[$0]=1; next} !reachable[$0] {bad=1} END {exit bad}' - "$queue_file" ||
      fail 'pending commit outside history head'
  fi
fi
printf 'branch: %s\nhead: %s\ncheckpoint: %s\n' "$branch" "$head" "$checkpoint"
