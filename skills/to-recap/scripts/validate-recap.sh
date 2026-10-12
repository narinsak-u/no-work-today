#!/usr/bin/env bash
set -euo pipefail

# Usage: validate-recap.sh REPOSITORY RECAP [SELECTED_IDS [EXPECTED_HEAD]]
# SELECTED_IDS lists every scoped commit once, oldest-first (one full ID per line).
if (( $# < 2 || $# > 4 )); then
  echo 'usage: validate-recap.sh REPOSITORY RECAP [SELECTED_IDS [EXPECTED_HEAD]]' >&2; exit 2
fi
repo=$1
recap=$2
selected=${3:-}
expected_head=${4:-}
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
  in_entry && /^- \*\*Important files:\*\* / {files++}
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
if LC_ALL=C grep -Eiq '(-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|(^|[^A-Za-z0-9_])(AWS_SECRET_ACCESS_KEY|GITHUB_TOKEN|API_KEY|PASSWORD)[[:space:]]*[:=][[:space:]]*[^[:space:]]+|\b(sk_live_|ghp_|github_pat_)[A-Za-z0-9_]+)' "$recap"; then
  fail 'possible secret value'
fi
if [[ -n $selected ]]; then
  [[ -f $selected ]] || fail 'commit list missing'
  # Check the entire selected set against the commit fields (never just one page).
  awk '
    FILENAME==ARGV[1] {
      if ($0 !~ /^[0-9a-f]+$/ || (length($0)!=40 && length($0)!=64) || want[$0]++) bad=1
      ids[++n]=$0
      next
    }
    /^- \*\*Commits:\*\* / {
      parts=split($0, tokens, "`")
      for (i=2; i<parts; i+=2) {
        hash=tokens[i]
        if (hash ~ /^[0-9a-f]+$/ && (length(hash)==40 || length(hash)==64)) found[hash]++
      }
    }
    END {for (i=1;i<=n;i++) if(found[ids[i]]!=1) bad=1; if (bad) exit 1}
  ' "$selected" "$recap" || fail 'selected commits missing or repeated'
  last=$(awk 'NF {last=$0} END {print last}' "$selected")
  checkpoint=$(awk '/^last_commit: / {print $2}' "$recap")
  [[ -z $last || $last == "$checkpoint" ]] || fail 'checkpoint does not match final selected commit'
  head=$(git -C "$repo" rev-parse HEAD)
  [[ $checkpoint == "$head" ]] || fail 'full range not represented at checkpoint'
  branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD) || fail 'branch changed'
  grep -Fqx -- "- **HEAD:** \`$head\` on \`$branch\`" "$recap" || fail 'Current Point HEAD or branch disagrees with Git'
  grep -Fqx -- "- **Recap checkpoint:** \`$checkpoint\`" "$recap" || fail 'Current Point checkpoint disagrees with state'
  grep -Fqx -- '- **Pending committed history:** None' "$recap" || fail 'selected history still marked pending'
  if grep -q '^pending_commits: ' "$recap"; then
    grep -q '^pending_commits: none$' "$recap" || fail 'pending commits left unrepresented'
  fi
fi
printf 'recap valid: %s\n' "$recap"
