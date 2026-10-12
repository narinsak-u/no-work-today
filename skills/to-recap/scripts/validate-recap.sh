#!/usr/bin/env bash
set -euo pipefail

# Usage: validate-recap.sh REPOSITORY RECAP [SELECTED_IDS EXPECTED_HEAD INITIAL|PRIOR_RECAP]
# SELECTED_IDS lists every scoped commit once, oldest-first (one full ID per line).
if (( $# != 2 && $# != 5 )); then
  echo 'usage: validate-recap.sh REPOSITORY RECAP [SELECTED_IDS EXPECTED_HEAD INITIAL|PRIOR_RECAP]' >&2; exit 2
fi
repo=$1
recap=$2
selected=${3:-}
expected_head=${4:-}
source_recap=${5:-}
fail() { echo "invalid recap: $*" >&2; exit 1; }
bash "$(dirname "$0")/validate-checkpoint.sh" "$repo" "$recap" "$expected_head" >/dev/null || fail 'unsafe state or checkpoint'
awk '
  {sub(/\r$/, "")}
  /^# Project Recap$/ {title++}
  /^## Scope$/ {scope++}
  /^## Current Point$/ {current++; in_entry=0}
  /^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] / {entries++; in_entry=1}
  in_entry && /^- \*\*Category:\*\* / {categories++;
    if ($0 !~ /^- \*\*Category:\*\* (features|fixes|refactors|infrastructure|testing|documentation|security|performance)$/) invalid=1}
  in_entry && /^- \*\*Status:\*\* / {statuses++;
    if ($0 !~ /^- \*\*Status:\*\* (Completed|Partial|In progress|Blocked|Needs verification)$/) invalid=1}
  in_entry && /^- \*\*What \/ why:\*\* / {whys++}
  in_entry && /^- \*\*Important files:\*\*($| )/ {files++}
  in_entry && /^- \*\*Commits:\*\* / {commits++}
  in_entry && /^- \*\*Impact:\*\* / {impacts++}
  in_entry && /^- \*\*Junior notes:\*\* / {notes++}
  in_entry && /^- \*\*Verification:\*\* / {verifications++}
  /^- \*\*HEAD:\*\* / {heads++}
  /^- \*\*Recap checkpoint:\*\* / {checkpoints++}
  /^- \*\*Pending committed history:\*\* / {pending++}
  /^- \*\*Committed work:\*\* / {committed++}
  /^- \*\*Uncommitted work:\*\* / {uncommitted++}
  /^- \*\*Next safe point:\*\* / {safe_points++}
  END {if (invalid || title!=1 || scope!=1 || current!=1 || entries<1 || categories!=entries || statuses!=entries || whys!=entries || files!=entries || commits!=entries || impacts!=entries || notes!=entries || verifications!=entries || heads!=1 || checkpoints!=1 || pending!=1 || committed!=1 || uncommitted!=1 || safe_points!=1) exit 1}
' "$recap" || fail 'required sections or work-entry fields missing'
if LC_ALL=C awk '
  function placeholder(value, quote, tail) {
    if (value ~ /^[`"\047]/) {
      quote=substr(value, 1, 1)
      value=substr(value, 2)
    }
    if (!match(value, /^\[(redacted|masked|placeholder|your_[[:alnum:]_]+|user|username|password|api_key|access_token|secret_key|token)\]/)) return 0
    tail=substr(value, RLENGTH+1)
    if (quote != "") {
      if (substr(tail, 1, 1) != quote) return 0
      tail=substr(tail, 2)
    }
    return tail == "" || tail ~ /^[[:space:]]/
  }
  {
    line=tolower($0)
    if (line ~ /-----begin (rsa |ec |openssh )?private key-----/ ||
        line ~ /(^|[^[:alnum:]_])(sk_live_|ghp_|github_pat_)[[:alnum:]_]+/) bad=1

    # Look at the value, not just the key: names and redaction placeholders
    # are safe, while a namespace prefix cannot hide a credential assignment.
    rest=line
    while (match(rest, /(^|[^[:alnum:]_])([[:alnum:]_]+_)?(aws_secret_access_key|password|api_key|access_token|secret_key|token)[[:space:]]*[:=][[:space:]]*/)) {
      value=substr(rest, RSTART+RLENGTH)
      if (value !~ /^$/ && !placeholder(value)) bad=1
      rest=substr(rest, RSTART+RLENGTH)
    }

    # Match authority user-info, not ordinary URLs or unrelated prose.
    rest=line
    while (match(rest, /(postgres(ql)?|mysql|mongodb(\+srv)?|rediss?|amqps?|https?):\/\/[^[:space:]\/?#]+/)) {
      authority=substr(rest, RSTART, RLENGTH)
      remaining=substr(rest, RSTART+RLENGTH)
      sub(/^[^:]+:\/\//, "", authority)
      userinfo=authority
      if (authority ~ /@[^@]+$/) sub(/@[^@]+$/, "", userinfo)
      else if (authority ~ /%40[^%]+$/) sub(/%40[^%]+$/, "", userinfo)
      else userinfo=""
      if (match(userinfo, /(:|%3a)/)) {
        userinfo=substr(userinfo, RSTART+RLENGTH)
        if (userinfo != "" && !placeholder(userinfo)) bad=1
      }
      rest=remaining
    }
  }
  END {exit !bad}
' "$recap"; then
  fail 'possible secret value'
fi
if [[ -n $selected ]]; then
  [[ -f $selected ]] || fail 'commit list missing'
  # Account for every selected commit only in dated work-entry commit fields,
  # not in Current Point or other prose (including lookalike commit fields).
  awk '
    FILENAME==ARGV[1] {
      if ($0 !~ /^[0-9a-f]+$/ || (length($0)!=40 && length($0)!=64) || want[$0]++) bad=1
      ids[++n]=$0
      next
    }
    /^## / {
      in_entry=($0 ~ /^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] /)
    }
    in_entry && /^- \*\*Commits:\*\* / {
      parts=split($0, tokens, "`")
      for (i=2; i<parts; i+=2) {
        hash=tokens[i]
        if (hash ~ /^[0-9a-f]+$/ && (length(hash)==40 || length(hash)==64)) found[hash]++
      }
    }
    END {for (i=1;i<=n;i++) if(found[ids[i]]!=1) bad=1; if (bad) exit 1}
  ' "$selected" "$recap" || fail 'selected commits missing or repeated'
  last=$(awk 'NF {last=$0} END {print last}' "$selected")
  checkpoint=$(awk '{sub(/\r$/, "")} /^last_commit: / {print $2}' "$recap")
  [[ -z $last || $last == "$checkpoint" ]] || fail 'checkpoint does not match final selected commit'
  head=$(git -C "$repo" rev-parse HEAD)
  [[ $checkpoint == "$head" ]] || fail 'full range not represented at checkpoint'
  # Derive the expected set from Git and the original boundary, not from
  # the agent-supplied list alone: an omitted middle commit must fail.
  if [[ $source_recap == INITIAL ]]; then
    cmp -s "$selected" <(git -C "$repo" rev-list --topo-order --max-count=100 "$head" |
      awk '{ids[++n]=$0} END {for (i=n; i>=1; i--) print ids[i]}') ||
      fail 'selected history does not cover the complete initial window'
  else
    [[ -f $source_recap ]] || fail 'original recap missing'
    if grep -q '^output_sha256: ' "$source_recap"; then
      bash "$(dirname "$0")/validate-checkpoint.sh" "$repo" "$source_recap" "$head" >/dev/null ||
        fail 'original recap boundary unsafe'
    fi
    # All published content before the mutable Current Point is append-only:
    # existing Scope and dated entries must be the exact prefix of the draft.
    prefix_bytes=$(sed '/^## Current Point/,$d' "$source_recap" | wc -c)
    cmp -s -n "$prefix_bytes" <(sed '/^## Current Point/,$d' "$source_recap") <(sed '/^## Current Point/,$d' "$recap") ||
      fail 'previous recap entries changed'
    base=$(awk '{sub(/\r$/, "")} /^last_commit: / {print $2}' "$source_recap")
    [[ $base =~ ^[0-9a-f]{40,64}$ ]] &&
      git -C "$repo" merge-base --is-ancestor "$base" "$head" ||
      fail 'original checkpoint not an ancestor'
    if grep -q '^history_head: ' "$source_recap"; then
      history_head=$(awk '{sub(/\r$/, "")} /^history_head: / {print $2}' "$source_recap")
      pending_ids=$(awk '{sub(/\r$/, "")} /^pending_commits: / {print substr($0,18)}' "$source_recap")
      [[ -n $pending_ids ]] || fail 'original pending queue missing'
      if [[ $pending_ids == none ]]; then
        cmp -s "$selected" <(git -C "$repo" rev-list --topo-order --reverse "$history_head..$head") ||
          fail 'selected history does not cover the complete checkpoint range'
      else
        cmp -s "$selected" <(awk -v pending="$pending_ids" '
          BEGIN {split(pending, queue, " "); for (i in queue) want[queue[i]]=1}
          FILENAME==ARGV[1] {want[$0]=1; next}
          want[$0] {print}
        ' <(git -C "$repo" rev-list "$history_head..$head") <(git -C "$repo" rev-list --topo-order --reverse "$head")) ||
          fail 'selected history does not cover the complete pending range'
      fi
    else
      grep -q '^pending_commits: ' "$source_recap" && fail 'original pending queue lacks history head'
      cmp -s "$selected" <(git -C "$repo" rev-list --topo-order --reverse "$base..$head") ||
        fail 'selected history does not cover the complete checkpoint range'
    fi
  fi
  branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD) || fail 'branch changed'
  sed 's/\r$//' "$recap" | grep -Fx -- "- **HEAD:** \`$head\` on \`$branch\`" >/dev/null || fail 'Current Point HEAD or branch disagrees with Git'
  sed 's/\r$//' "$recap" | grep -Fx -- "- **Recap checkpoint:** \`$checkpoint\`" >/dev/null || fail 'Current Point checkpoint disagrees with state'
  sed 's/\r$//' "$recap" | grep -Fx -- '- **Pending committed history:** None' >/dev/null || fail 'selected history still marked pending'
  if grep -q '^pending_commits: ' "$recap"; then
    sed 's/\r$//' "$recap" | grep -Fx -- 'pending_commits: none' >/dev/null || fail 'pending commits left unrepresented'
  fi
fi
printf 'recap valid: %s\n' "$recap"
