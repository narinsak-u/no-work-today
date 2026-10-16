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
expected_dir=$(mktemp -d "${TMPDIR:-/tmp}/recap-validation.XXXXXX")
trap 'rm -rf "$expected_dir"' EXIT
fixture_expected_initial="$expected_dir/initial"
fixture_expected_history="$expected_dir/history"
fixture_expected_batch="$expected_dir/batch"
bash "$(dirname "$0")/validate-checkpoint.sh" "$repo" "$recap" "$expected_head" >/dev/null || fail 'unsafe state or checkpoint'
awk '
  {sub(/\r$/, "")}
  /^# Project Recap$/ {title++}
  /^## Scope$/ {scope++}
  /^## Current Point$/ {current++; in_entry=0}
  /^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] / {entries++; in_entry=1; entry_notes=0}
  in_entry && /^- \*\*Category:\*\* / {categories++;
    if ($0 !~ /^- \*\*Category:\*\* (features|fixes|refactors|infrastructure|testing|documentation|security|performance)$/) invalid=1}
  in_entry && /^- \*\*Status:\*\* / {statuses++;
    if ($0 !~ /^- \*\*Status:\*\* (Completed|Partial|In progress|Blocked|Needs verification)$/) invalid=1}
  in_entry && /^- \*\*What \/ why:\*\* / {whys++}
  in_entry && /^- \*\*Important files:\*\*($| )/ {files++}
  in_entry && /^- \*\*Commits:\*\* / {commits++}
  in_entry && /^- \*\*Impact:\*\* / {impacts++}
  in_entry && /^- \*\*Junior notes:\*\* / {entry_notes++; if (entry_notes > 1) invalid=1}
  in_entry && /^- \*\*Verification:\*\* / {verifications++}
  /^- \*\*HEAD:\*\* / {heads++}
  /^- \*\*Recap checkpoint:\*\* / {checkpoints++}
  /^- \*\*Pending committed history:\*\* / {pending++}
  /^- \*\*Committed work:\*\* / {committed++}
  /^- \*\*Uncommitted work:\*\* / {uncommitted++}
  /^- \*\*Next safe point:\*\* / {safe_points++}
  END {if (invalid || title!=1 || scope!=1 || current!=1 || entries<1 || categories!=entries || statuses!=entries || whys!=entries || files!=entries || commits!=entries || impacts!=entries || verifications!=entries || heads!=1 || checkpoints!=1 || pending!=1 || committed!=1 || uncommitted!=1 || safe_points!=1) exit 1}
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
    return tail == "" || tail ~ /^[[:space:]]/ ||
      tail ~ /^[,;][[:space:]]*(([[:alnum:]_]+_)?(aws_secret_access_key|password|api_key|access_token|secret_key|token))[[:space:]]*[:=]/
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
      rest=value
      if (value !~ /^$/ && !placeholder(value)) bad=1
    }

    # Match authority user-info, not ordinary URLs or unrelated prose.
    rest=line
    while (match(rest, /(postgres(ql)?|mysql|mongodb(\+srv)?|rediss?|amqps?|https?):\/\/[^[:space:]\/?#]+/)) {
      authority=substr(rest, RSTART, RLENGTH)
      remaining=substr(rest, RSTART+RLENGTH)
      sub(/^[^:]+:\/\//, "", authority)
      userinfo=authority
      scan=authority
      offset=at=0
      while (match(scan, /@|%40/)) {
        at=offset+RSTART
        offset+=RSTART+RLENGTH-1
        scan=substr(scan, RSTART+RLENGTH)
      }
      userinfo=(at ? substr(authority, 1, at-1) : "")
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
  # Selected full IDs must occur exactly once in dated entries, inside their
  # collapsed technical evidence; IDs in Current Point or prose do not count.
  awk '
    FILENAME==ARGV[1] {
      if ($0 !~ /^[0-9a-f]+$/ || (length($0)!=40 && length($0)!=64) || want[$0]++) bad=1
      ids[++n]=$0
      next
    }
    /^## / {
      in_entry=($0 ~ /^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] /)
      in_details=0
    }
    in_entry && /<details>/ {in_details=1}
    in_entry && /<\/details>/ {in_details=0}
    in_entry && /^- \*\*Commits:\*\* / {
      parts=split($0, tokens, "`")
      for (i=2; i<parts; i+=2) {
        hash=tokens[i]
        if (hash ~ /^[0-9a-f]+$/ && (length(hash)==40 || length(hash)==64)) {
          found[hash]++
          if (in_details) collapsed[hash]++
        }
      }
    }
    END {
      for (i=1;i<=n;i++) if(found[ids[i]]!=1 || collapsed[ids[i]]!=1) bad=1
      if (bad) exit 1
    }
  ' "$selected" "$recap" || fail 'selected commits missing, repeated, or outside collapsed evidence'
  selected_count=$(awk 'END {print NR+0}' "$selected")
  (( selected_count <= 100 )) || fail 'invocation selected more than 100 commits'
  last=$(awk 'NF {last=$0} END {print last}' "$selected")
  checkpoint=$(awk '{sub(/\r$/, "")} /^last_commit: / {print $2}' "$recap")
  [[ -z $last || $last == "$checkpoint" ]] || fail 'checkpoint does not match final selected commit'
  head=$(git -C "$repo" rev-parse HEAD)
  if [[ $source_recap == INITIAL ]]; then
    expected_ids="$fixture_expected_initial"
    git -C "$repo" rev-list --topo-order --max-count=100 "$head" |
      awk '{ids[++n]=$0} END {for (i=n; i>=1; i--) print ids[i]}' > "$expected_ids"
    older='no'
    if (( $(git -C "$repo" rev-list --count --max-count=101 "$head") > 100 )); then older='yes'; fi
    cmp -s "$selected" "$expected_ids" ||
      fail 'selected history does not cover the complete initial window'
    [[ $checkpoint == "$head" ]] || fail 'initial checkpoint must cover selected HEAD'
    draft_history_head=$(awk '{sub(/\r$/, "")} /^history_head: / {print $2}' "$recap")
    [[ $draft_history_head == "$head" ]] || fail 'initial history head does not match captured HEAD'
    pending=no
  else
    [[ -f $source_recap ]] || fail 'original recap missing'
    if grep -q '^output_sha256: ' "$source_recap"; then
      bash "$(dirname "$0")/validate-checkpoint.sh" "$repo" "$source_recap" "$head" >/dev/null ||
        fail 'original recap boundary unsafe'
    fi
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
        git -C "$repo" rev-list --topo-order --reverse "$history_head..$head" > "$fixture_expected_history"
      else
        awk -v pending="$pending_ids" '
          BEGIN {split(pending, queue, " "); for (i in queue) want[queue[i]]=1}
          FILENAME==ARGV[1] {want[$0]=1; next}
          want[$0] {print}
        ' <(git -C "$repo" rev-list "$history_head..$head") <(git -C "$repo" rev-list --topo-order --reverse "$head") > "$fixture_expected_history"
      fi
      expected_full="$fixture_expected_history"
    else
      grep -q '^pending_commits: ' "$source_recap" && fail 'original pending queue lacks history head'
      expected_full="$fixture_expected_history"
      git -C "$repo" rev-list --topo-order --reverse "$base..$head" > "$expected_full"
    fi
    expected_batch="$fixture_expected_batch"
    awk 'NR<=100' "$expected_full" > "$expected_batch"
    cmp -s "$selected" "$expected_batch" || fail 'selected history does not cover the oldest pending batch'
    [[ $checkpoint == "$(awk 'END {print}' "$expected_batch")" ]] ||
      fail 'checkpoint does not match final selected commit'
    pending_count=$(awk -v selected="$selected_count" 'NR>selected {n++} END {print n+0}' "$expected_full")
    # A scalar checkpoint cannot safely resume a partially represented merge history.
    if (( pending_count > 0 )); then
      pending=yes
      next_unrepresented=$(awk -v selected="$selected_count" 'NR==selected+1 {print; exit}' "$expected_full")
      draft_history_head=$(awk '{sub(/\r$/, "")} /^history_head: / {print $2}' "$recap")
      draft_pending=$(awk '{sub(/\r$/, "")} /^pending_commits: / {print substr($0,18)}' "$recap")
      [[ $draft_history_head == "$head" && -n $draft_pending && $draft_pending != none ]] ||
        fail 'remaining history requires pinned pending queue'
      expected_pending=$(awk -v selected="$selected_count" 'NR>selected {if (n) printf " "; printf "%s", $0; n++} END {if (n) printf "\n"}' "$expected_full")
      [[ $draft_pending == "$expected_pending" ]] || fail 'pending queue does not match remaining history'
    else
      draft_history_head=$(awk '{sub(/\r$/, "")} /^history_head: / {print $2}' "$recap")
      [[ $draft_history_head == "$head" ]] || fail 'history head does not match captured HEAD'
      pending=no
      next_unrepresented=''
    fi
  fi
  branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD) || fail 'branch changed'
  sed 's/\r$//' "$recap" | grep -Fx -- "- **HEAD:** \`$head\` on \`$branch\`" >/dev/null || fail 'Current Point HEAD or branch disagrees with Git'
  sed 's/\r$//' "$recap" | grep -Fx -- "- **Recap checkpoint:** \`$checkpoint\`" >/dev/null || fail 'Current Point checkpoint disagrees with state'
  if [[ $pending == yes ]]; then
    if [[ $pending_count == 1 ]]; then
      pending_noun=commit
      pending_verb=remains
    else
      pending_noun=commits
      pending_verb=remain
    fi
    sed 's/\r$//' "$recap" | grep -Fx -- "- **Pending committed history:** $pending_count $pending_noun $pending_verb; oldest unrepresented: \`$next_unrepresented\`" >/dev/null ||
      fail 'pending committed history does not match the remaining batch'
  else
    sed 's/\r$//' "$recap" | grep -Fx -- '- **Pending committed history:** None' >/dev/null ||
      fail 'completed history still marked pending'
    if grep -q '^pending_commits: ' "$recap"; then
      sed 's/\r$//' "$recap" | grep -Fx -- 'pending_commits: none' >/dev/null || fail 'pending commits left unrepresented'
    fi
  fi
fi
printf 'recap valid: %s\n' "$recap"
