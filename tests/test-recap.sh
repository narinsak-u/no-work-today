#!/usr/bin/env bash
set -euo pipefail

skill="$(cd "$(dirname "$0")/../skills/to-recap" && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/recap tests.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT
repo="$fixture/project with spaces"
mkdir -p "$repo/docs"
git -C "$repo" init -q
git -C "$repo" config user.email recap@example.test
git -C "$repo" config user.name Recap
git -C "$repo" commit --allow-empty -qm start
branch="$(git -C "$repo" branch --show-current)"
initial="$(git -C "$repo" rev-parse HEAD)"
for ((n=1; n<=110; n++)); do git -C "$repo" commit --allow-empty -qm "initial $n"; done
head="$(git -C "$repo" rev-parse HEAD)"
context="$(bash "$skill/scripts/collect-git-context.sh" "$repo")"
[[ "$context" == *"mode: initial"* && "$context" == *"total: 100"* && "$context" == *"head: $head"* && "$context" == *"older_history: yes"* ]] || exit 1
oldest="$(git -C "$repo" rev-list --max-count=100 HEAD | awk 'END {print}')"
[[ "$context" == *"coverage_oldest: $oldest"* && "$context" == *"commit: $oldest"* ]] || exit 1
[[ "$(printf '%s\n' "$context" | awk '/^commit: / {n++} END {print n+0}')" == 100 ]] || exit 1
[[ "$context" == *"has_more: no"* ]] || exit 1
mkdir -p "$fixture/short history"
git -C "$fixture/short history" init -q
git -C "$fixture/short history" -c user.email=recap@example.test -c user.name=Recap commit --allow-empty -qm one
git -C "$fixture/short history" -c user.email=recap@example.test -c user.name=Recap commit --allow-empty -qm two
short="$(bash "$skill/scripts/collect-git-context.sh" "$fixture/short history")"
[[ "$short" == *"total: 2"* && "$short" == *"older_history: no"* ]] || exit 1

# Initial publications also pin their history state to the captured HEAD.
initial_repo="$fixture/short history"
initial_branch="$(git -C "$initial_repo" branch --show-current)"
initial_head="$(git -C "$initial_repo" rev-parse HEAD)"
initial_stale_head="$(git -C "$initial_repo" rev-parse HEAD^)"
initial_selected="$fixture/initial-selected"
git -C "$initial_repo" rev-list --topo-order --reverse "$initial_head" > "$initial_selected"
initial_inline="$(awk '{printf "%s`%s` — selected commit", separator, $0; separator="; "}' "$initial_selected")"
cat > "$fixture/initial-unsigned" <<DOC
# Project Recap
## Scope
- **Committed range:** Initial window: `$initial_stale_head` through `$initial_head`, inclusive.
- **Older history:** None; all reachable commits covered
## 2026-10-12 — Initial history
- **Category:** testing
- **Status:** Completed
- **What / why:** Captured the initial history.
<details>
<summary>Technical details and commit evidence</summary>
- **Important files:** none
- **Commits:** $initial_inline
- **Junior notes:** None.
- **Verification:** not run
</details>
- **Impact:** Initial history captured.
## Current Point
- **HEAD:** \`$initial_head\` on \`$initial_branch\`
- **Recap checkpoint:** \`$initial_head\`
- **Pending committed history:** None
- **Committed work:** Initial history captured.
- **Uncommitted work:** None.
- **Verification:** not run
- **Next safe point:** None identified.
<!-- recap-state
branch: $initial_branch
last_commit: $initial_head
last_updated: 2026-10-12
history_head: $initial_head
pending_commits: none
-->
DOC
initial_hash="$( (sha256sum "$fixture/initial-unsigned" 2>/dev/null || shasum -a 256 "$fixture/initial-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$initial_hash" '/^-->$/ {print "output_sha256: " hash} {print}' \
  "$fixture/initial-unsigned" > "$fixture/initial-valid-recap"
bash "$skill/scripts/validate-recap.sh" "$initial_repo" "$fixture/initial-valid-recap" "$initial_selected" "$initial_head" INITIAL
initial_digest="$(git -C "$initial_repo" hash-object "$fixture/initial-valid-recap")"
bash "$skill/scripts/validate-recap.sh" "$initial_repo" "$fixture/initial-valid-recap" "$initial_selected" "$initial_head" INITIAL
[[ "$(git -C "$initial_repo" hash-object "$fixture/initial-valid-recap")" == "$initial_digest" ]] || exit 1

# A first recap of a long history exposes the inclusive oldest represented
# commit and explicitly excludes everything older than the selected 100.
long_selected="$fixture/long-initial-selected"
git -C "$repo" rev-list --topo-order --max-count=100 "$head" |
  awk '{ids[++n]=$0} END {for (i=n; i>=1; i--) print ids[i]}' > "$long_selected"
long_inline="$(awk '{printf "%s`%s` — selected commit", separator, $0; separator="; "}' "$long_selected")"
cat > "$fixture/long-initial-unsigned" <<DOC
# Project Recap
## Scope
- **Committed range:** Initial window: \`$oldest\` through \`$head\`, inclusive.
- **Older history:** Outside initial coverage
## 2026-10-12 — Initial history
- **Category:** testing
- **Status:** Completed
- **What / why:** Captured only the newest 100 commits.
<details>
<summary>Technical details and commit evidence</summary>
- **Important files:** none
- **Commits:** $long_inline
- **Verification:** not run
</details>
- **Impact:** Initial history captured.
## Current Point
- **HEAD:** \`$head\` on \`$branch\`
- **Recap checkpoint:** \`$head\`
- **Pending committed history:** None
- **Committed work:** Only the initial window was captured.
- **Uncommitted work:** None.
- **Verification:** not run
- **Next safe point:** Inspect older history separately if needed.
<!-- recap-state
branch: $branch
last_commit: $head
last_updated: 2026-10-12
history_head: $head
pending_commits: none
-->
DOC
sign_initial() {
  local digest
  digest="$( (sha256sum "$1" 2>/dev/null || shasum -a 256 "$1") | awk 'NR==1 {print $1}')"
  awk -v hash="$digest" '/^-->$/ {print "output_sha256: " hash} {print}' "$1" > "$2"
}
sign_initial "$fixture/long-initial-unsigned" "$fixture/long-initial-recap"
bash "$skill/scripts/validate-recap.sh" "$repo" "$fixture/long-initial-recap" "$long_selected" "$head" INITIAL
for case in wrong_boundary wrong_older missing_older; do
  case "$case" in
    wrong_boundary) awk -v wrong="$initial" '/^- \*\*Committed range:\*\*/ {sub(/`[0-9a-f]+`/, "`" wrong "`")} {print}' "$fixture/long-initial-unsigned" > "$fixture/initial-tampered" ;;
    wrong_older) awk '/^- \*\*Older history:\*\*/ {$0="- **Older history:** None; all reachable commits covered"} {print}' "$fixture/long-initial-unsigned" > "$fixture/initial-tampered" ;;
    missing_older) awk '!/^- \*\*Older history:\*\*/' "$fixture/long-initial-unsigned" > "$fixture/initial-tampered" ;;
  esac
  sign_initial "$fixture/initial-tampered" "$fixture/initial-tampered-signed"
  if bash "$skill/scripts/validate-recap.sh" "$repo" "$fixture/initial-tampered-signed" "$long_selected" "$head" INITIAL >/dev/null 2>&1; then
    echo "Validator accepted $case in a signed initial recap" >&2; exit 1
  fi
done
awk '/^- \*\*Older history:\*\*/ {$0="- **Older history:** Outside initial coverage"} {print}' \
  "$fixture/initial-unsigned" > "$fixture/initial-tampered"
sign_initial "$fixture/initial-tampered" "$fixture/initial-tampered-signed"
if bash "$skill/scripts/validate-recap.sh" "$initial_repo" "$fixture/initial-tampered-signed" "$initial_selected" "$initial_head" INITIAL >/dev/null 2>&1; then
  echo 'Validator accepted excluded older history when all commits were covered' >&2; exit 1
fi
awk -v stale="$initial_stale_head" '
  /^history_head: / {print "history_head: " stale; next}
  /^output_sha256: / {next}
  {print}
' "$fixture/initial-valid-recap" > "$fixture/initial-stale-unsigned"
initial_stale_hash="$( (sha256sum "$fixture/initial-stale-unsigned" 2>/dev/null || shasum -a 256 "$fixture/initial-stale-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$initial_stale_hash" '/^-->$/ {print "output_sha256: " hash} {print}' \
  "$fixture/initial-stale-unsigned" > "$fixture/initial-stale-recap"
if initial_error="$(bash "$skill/scripts/validate-recap.sh" "$initial_repo" "$fixture/initial-stale-recap" "$initial_selected" "$initial_head" INITIAL 2>&1)"; then
  echo 'Validator accepted an initial recap with stale history_head' >&2; exit 1
fi
[[ "$initial_error" == *'initial history head does not match captured HEAD'* ]] ||
  { printf 'Wrong initial history-head rejection: %s\n' "$initial_error" >&2; exit 1; }

# Each invocation returns one bounded, oldest-first history batch. Advancing
# the checkpoint to its final ID continues the next run without gaps.
checkpoint="$head"
for ((n=1; n<=1007; n++)); do git -C "$repo" commit --allow-empty -qm "delta $n"; done
head="$(git -C "$repo" rev-parse HEAD)"
expected="$fixture/expected"
actual="$fixture/actual"
git -C "$repo" rev-list --topo-order --reverse "$checkpoint..$head" > "$expected"
: > "$actual"
remaining=1007
while [[ "$checkpoint" != "$head" ]]; do
  page="$(bash "$skill/scripts/collect-git-context.sh" "$repo" "$checkpoint" 0 "$head")"
  [[ "$page" == *"total: $remaining"* && "$page" == *"offset: 0"* ]] || exit 1
  count="$(printf '%s\n' "$page" | awk '/^commit: / {n++} END {print n+0}')"
  if ((remaining > 100)); then
    [[ "$count" == 100 && "$page" == *"has_more: yes"* ]] || exit 1
  else
    [[ "$count" == "$remaining" && "$page" == *"has_more: no"* ]] || exit 1
  fi
  selected="$(printf '%s\n' "$page" | awk '/^commit: / {print $2}')"
  printf '%s\n' "$selected" >> "$actual"
  checkpoint="$(printf '%s\n' "$selected" | awk 'END {print}')"
  ((remaining -= count)) || :
done
cmp "$expected" "$actual"
initial_repeat="$(bash "$skill/scripts/collect-git-context.sh" "$repo")"
[[ "$initial_repeat" == *"mode: initial"* && "$initial_repeat" == *"total: 100"* && "$initial_repeat" == *"has_more: no"* ]] || exit 1
repeat="$(bash "$skill/scripts/collect-git-context.sh" "$repo" "$head" 0 "$head")"
[[ "$repeat" == *"total: 0"* && "$repeat" == *"has_more: no"* ]] || exit 1
git -C "$repo" commit --allow-empty -qm 'move HEAD after the captured history batch'
if bash "$skill/scripts/collect-git-context.sh" "$repo" "$checkpoint" 0 "$head" >/dev/null 2>&1; then
  echo 'Collector accepted changed HEAD' >&2; exit 1
fi
if bash "$skill/scripts/collect-git-context.sh" "$repo" "$initial" 100 "$head" >/dev/null 2>&1; then
  echo 'Collector accepted another batch page in one invocation' >&2; exit 1
fi
if bash "$skill/scripts/collect-git-context.sh" "$repo" not-a-hash >/dev/null 2>&1; then
  echo 'Collector accepted invalid boundary' >&2; exit 1
fi

# File lists are bounded, with an explicit total and continuation offset.
for ((n=1; n<=12; n++)); do printf 'x\n' > "$repo/file $n"; git -C "$repo" add "file $n"; done
git -C "$repo" commit -qm files
files_commit="$(git -C "$repo" rev-parse HEAD)"
files="$(bash "$skill/scripts/changed-files.sh" "$repo" "$files_commit" 0 5)"
[[ "$files" == *"total: 12"* && "$files" == *"has_more: yes"* && "$files" == *'12 files changed'* ]] || exit 1
[[ "$(printf '%s\n' "$files" | awk '/^file: / {n++} END {print n+0}')" == 5 ]] || exit 1

# Fingerprint and state checks must never rewrite damaged or branch-mismatched recaps.
recap="$repo/docs/recap.md"
cat > "$recap" <<DOC
# Project Recap
## Scope
- **Committed range:** $checkpoint through $head inclusive; oldest included commit: $checkpoint.
## 2026-10-12 — Initial work
- **Category:** testing
- **Status:** Completed
- **What / why:** Confirmed history.
<details>
<summary>Technical details and commit evidence</summary>
- **Important files:**
  - \`file 1\` — added in this commit.
- **Commits:** \`$files_commit\`
- **Junior notes:** None.
- **Verification:** not run
</details>
- **Impact:** Unknown
## Current Point
- **HEAD:** \`$files_commit\` on \`$branch\`
- **Recap checkpoint:** \`$files_commit\`
- **Pending committed history:** None
- **Committed work:** Above.
- **Uncommitted work:** None.
- **Verification:** not run
- **Next safe point:** None identified.
<!-- recap-state
branch: $branch
last_commit: $files_commit
last_updated: 2026-10-12
-->
DOC
hash="$( (sha256sum "$recap" 2>/dev/null || shasum -a 256 "$recap") | awk 'NR==1 {print $1}')"
# Insert the fingerprint at the specified location without modifying the hashed content elsewhere.
awk -v hash="$hash" '/^-->$/ {print "output_sha256: " hash} {print}' "$recap" > "$fixture/signed"
cp "$fixture/signed" "$recap"
bash "$skill/scripts/validate-checkpoint.sh" "$repo" "$recap"
bash "$skill/scripts/validate-recap.sh" "$repo" "$recap"

# Each candidate remains structurally valid and correctly signed: rejection
# must come from the secret check, without altering the published checkpoint.
published_digest="$(git -C "$repo" hash-object "$recap")"
sign_candidate() {
  awk -v detail="$1" '
    /^- \*\*What \/ why:\*\* Confirmed history\.$/ {print $0 " " detail; next}
    !/^output_sha256: / {print}
  ' "$recap" > "$fixture/candidate-unsigned"
  candidate_hash="$( (sha256sum "$fixture/candidate-unsigned" 2>/dev/null || shasum -a 256 "$fixture/candidate-unsigned") | awk 'NR==1 {print $1}')"
  awk -v hash="$candidate_hash" '/^-->$/ {print "output_sha256: " hash} {print}' "$fixture/candidate-unsigned" > "$fixture/candidate-recap"
  bash "$skill/scripts/validate-checkpoint.sh" "$repo" "$fixture/candidate-recap" >/dev/null
}
for detail in \
  'DB_PASSWORD=redRecapPassword29' \
  'DB_PASSWORD=[REDACTED]:redRecapSuffix29' \
  'DB_PASSWORD=[REDACTED];actual-secret' \
  'DB_PASSWORD=[REDACTED], fixture_credential' \
  'SERVICE_API_KEY=[masked]!redRecapSuffix29' \
  'AWS_SECRET_ACCESS_KEY=redRecapAws29' \
  'SERVICE_API_KEY: redRecapApiKey29' \
  'AUTH_ACCESS_TOKEN=redRecapAccess29' \
  'CACHE_SECRET_KEY: redRecapSecret29' \
  'DEPLOY_TOKEN=redRecapToken29' \
  'PASSWORD=redRecapBare29' \
  'API_KEY=redRecapBare29' \
  'ACCESS_TOKEN=redRecapBare29' \
  'SECRET_KEY=redRecapBare29' \
  'TOKEN=redRecapBare29' \
  'postgresql://reader:redRecapPg29@db.example.test/app' \
  'postgresql://reader:[REDACTED]:redRecapSuffix29@db.example.test/app' \
  'postgresql://reader:realpass%3A[REDACTED]@db.example.test/app' \
  'postgresql://reader%3Arealpass%3A[REDACTED]@db.example.test/app' \
  'postgresql://reader%3Afixture_credential%40db%2Eexample/app' \
  'mysql://reader:redRecapMysql29@db.example.test/app' \
  'mongodb://reader:redRecapMongo29@db.example.test/app' \
  'redis://reader:redRecapRedis29@db.example.test/0' \
  'amqp://reader:redRecapAmqp29@mq.example.test/vhost' \
  'http://reader:redRecapHttp29@service.example.test/api' \
  'https://reader:redRecapHttps29@service.example.test/api' \
  'postgres://reader:redRecapEncoded%4029@db.example.test/app' \
  'https://reader%40tenant:redRecapEncoded29@service.example.test/api'
do
  sign_candidate "$detail"
  if rejection="$(ulimit -t 3; bash "$skill/scripts/validate-recap.sh" "$repo" "$fixture/candidate-recap" 2>&1)"; then
    echo 'Validator accepted a signed credential-bearing recap' >&2; exit 1
  fi
  [[ "$rejection" == *'possible secret value'* && "$rejection" != *"$detail"* ]] ||
    { printf 'Unsafe or unexpected recap rejection diagnostic for %s: %s\n' "$detail" "$rejection" >&2; exit 1; }
  [[ "$(git -C "$repo" hash-object "$recap")" == "$published_digest" ]] ||
    { echo 'Rejected draft changed published recap' >&2; exit 1; }
done
for detail in \
  'DB_PASSWORD and SERVICE_API_KEY are configuration names, not values.' \
  'DB_PASSWORD=[REDACTED] and SERVICE_TOKEN: [redacted] are placeholders.' \
  'DB_PASSWORD=[REDACTED] harmless context follows.' \
  'DB_PASSWORD=[REDACTED]; SERVICE_API_KEY=[masked] are placeholders.' \
  'DB_PASSWORD="[REDACTED]" harmless context follows.' \
  'SERVICE_API_KEY=[masked]   extra prose.' \
  'postgresql://[USER]:[PASSWORD]@db.example.test/app is a redacted example.' \
  'postgresql://reader%3A[REDACTED]@db.example.test/app is redacted.' \
  'The recap checkpoint includes tested documentation work.'
do
  sign_candidate "$detail"
  bash "$skill/scripts/validate-recap.sh" "$repo" "$fixture/candidate-recap" >/dev/null ||
    { echo 'Validator rejected safe recap prose' >&2; exit 1; }
done
awk '/^output_sha256:/ {next} {printf "%s\r\n", $0}' "$recap" > "$fixture/crlf-unsigned"
crlf_hash="$( (sha256sum "$fixture/crlf-unsigned" 2>/dev/null || shasum -a 256 "$fixture/crlf-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$crlf_hash" '{sub(/\r$/, ""); if ($0=="-->") printf "output_sha256: %s\r\n", hash; printf "%s\r\n", $0}' "$fixture/crlf-unsigned" > "$fixture/crlf-recap"
bash "$skill/scripts/validate-checkpoint.sh" "$repo" "$fixture/crlf-recap"
printf '%s\n' "$files_commit" > "$fixture/selected"
previous="$(git -C "$repo" rev-parse "$files_commit^")"
awk -v base="$previous" '/^last_commit: / {print "last_commit: " base; next} /^output_sha256: / {next} {print}' "$recap" > "$fixture/prior-unsigned"
prior_hash="$( (sha256sum "$fixture/prior-unsigned" 2>/dev/null || shasum -a 256 "$fixture/prior-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$prior_hash" '/^-->$/ {print "output_sha256: " hash} {print}' "$fixture/prior-unsigned" > "$fixture/prior-recap"
awk '{printf "%s\r\n", $0}' "$fixture/prior-unsigned" > "$fixture/prior-crlf-unsigned"
prior_crlf_hash="$( (sha256sum "$fixture/prior-crlf-unsigned" 2>/dev/null || shasum -a 256 "$fixture/prior-crlf-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$prior_crlf_hash" '{sub(/\r$/, ""); if ($0=="-->") printf "output_sha256: %s\r\n", hash; printf "%s\r\n", $0}' "$fixture/prior-crlf-unsigned" > "$fixture/prior-crlf-recap"

# A new publication migrating a legacy recap must add current queue state.
awk -v current="$files_commit" '
  /^last_updated: / {print; print "history_head: " current; print "pending_commits: none"; next}
  /^output_sha256: / {next}
  {print}
' "$recap" > "$fixture/caught-up-unsigned"
caught_up_hash="$( (sha256sum "$fixture/caught-up-unsigned" 2>/dev/null || shasum -a 256 "$fixture/caught-up-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$caught_up_hash" '/^-->$/ {print "output_sha256: " hash} {print}' "$fixture/caught-up-unsigned" > "$recap"
cp "$recap" "$fixture/signed"
awk '/^output_sha256: / {next} {printf "%s\r\n", $0}' "$recap" > "$fixture/crlf-unsigned"
caught_up_crlf_hash="$( (sha256sum "$fixture/crlf-unsigned" 2>/dev/null || shasum -a 256 "$fixture/crlf-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$caught_up_crlf_hash" '{sub(/\r$/, ""); if ($0=="-->") printf "output_sha256: %s\r\n", hash; printf "%s\r\n", $0}' "$fixture/crlf-unsigned" > "$fixture/crlf-recap"
bash "$skill/scripts/validate-recap.sh" "$repo" "$recap" "$fixture/selected" "$files_commit" "$fixture/prior-recap"
bash "$skill/scripts/validate-recap.sh" "$repo" "$fixture/crlf-recap" "$fixture/selected" "$files_commit" "$fixture/prior-crlf-recap"
awk -v prior="$previous" '
  /^## Current Point$/ {
    print "## 2026-10-11 — Earlier work"
    print "- **Category:** testing"
    print "- **Status:** Completed"
    print "- **What / why:** Initial fixture history."
    print "- **Important files:** none"
    print "- **Commits:** `" prior "` — prior commit"
    print "- **Impact:** Unknown"
    print "- **Junior notes:** None."
    print "- **Verification:** not run"
  }
  { print }
' "$fixture/prior-unsigned" > "$fixture/history-unsigned"
history_hash="$( (sha256sum "$fixture/history-unsigned" 2>/dev/null || shasum -a 256 "$fixture/history-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$history_hash" '/^-->$/ {print "output_sha256: " hash} {print}' "$fixture/history-unsigned" > "$fixture/history-recap"
if history_error="$(bash "$skill/scripts/validate-recap.sh" "$repo" "$recap" "$fixture/selected" "$files_commit" "$fixture/history-recap" 2>&1)"; then
  echo 'Validator accepted removal of an earlier recap entry' >&2; exit 1
fi
[[ "$history_error" == *'previous recap entries changed'* ]] || { printf 'Wrong rejection: %s\n' "$history_error" >&2; exit 1; }
awk -v base="$checkpoint" '/^last_commit: / {print "last_commit: " base; next} /^output_sha256: / {next} {print}' "$recap" > "$fixture/old-unsigned"
old_hash="$( (sha256sum "$fixture/old-unsigned" 2>/dev/null || shasum -a 256 "$fixture/old-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$old_hash" '/^-->$/ {print "output_sha256: " hash} {print}' "$fixture/old-unsigned" > "$fixture/old-recap"
if gap_error="$(bash "$skill/scripts/validate-recap.sh" "$repo" "$recap" "$fixture/selected" "$files_commit" "$fixture/old-recap" 2>&1)"; then
  echo 'Validator accepted a selected list that skipped the earlier range' >&2; exit 1
fi
[[ "$gap_error" == *'selected history does not cover'* ]] || { printf 'Wrong rejection: %s\n' "$gap_error" >&2; exit 1; }

# A published checkpoint with pending history must not advance for IDs that
# appear only under Current Point, or for missing/repeated dated-entry IDs.
account_repo="$fixture/accounting project"
mkdir -p "$account_repo/docs"
git -C "$account_repo" init -q
git -C "$account_repo" config user.email recap@example.test
git -C "$account_repo" config user.name Recap
git -C "$account_repo" commit --allow-empty -qm checkpoint
account_base="$(git -C "$account_repo" rev-parse HEAD)"
account_branch="$(git -C "$account_repo" branch --show-current)"
git -C "$account_repo" commit --allow-empty -qm 'first pending batch'
account_first="$(git -C "$account_repo" rev-parse HEAD)"
git -C "$account_repo" commit --allow-empty -qm 'second pending batch'
account_second="$(git -C "$account_repo" rev-parse HEAD)"
account_prior="$account_repo/docs/recap.md"
cat > "$fixture/account-prior-unsigned" <<DOC
# Project Recap
## Scope
- **Committed range:** through $account_base.
## 2026-10-10 — Published checkpoint
- **Category:** testing
- **Status:** Completed
- **What / why:** Preserved prior work.
- **Important files:** none
- **Commits:** \`$account_base\`
- **Impact:** Checkpoint documented.
- **Junior notes:** None.
- **Verification:** not run
## Current Point
- **HEAD:** \`$account_second\` on \`$account_branch\`
- **Recap checkpoint:** \`$account_base\`
- **Pending committed history:** Two commits.
- **Committed work:** Earlier entry.
- **Uncommitted work:** None.
- **Next safe point:** Account for pending work.
<!-- recap-state
branch: $account_branch
last_commit: $account_base
last_updated: 2026-10-10
history_head: $account_second
pending_commits: $account_first $account_second
-->
DOC
account_hash="$( (sha256sum "$fixture/account-prior-unsigned" 2>/dev/null || shasum -a 256 "$fixture/account-prior-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$account_hash" '/^-->$/ {print "output_sha256: " hash} {print}' "$fixture/account-prior-unsigned" > "$account_prior"
git -C "$account_repo" commit --allow-empty -qm 'new commit after prior checkpoint'
account_last="$(git -C "$account_repo" rev-parse HEAD)"
printf '%s\n' "$account_first" "$account_second" "$account_last" > "$fixture/account-selected"
account_before="$(git -C "$account_repo" hash-object "$account_prior")"
account_draft="$fixture/account-draft"
make_account_draft() {
  local entry_commits=$1 current_note=$2 draft_hash
  awk -v ids="$entry_commits" -v note="$current_note" -v latest="$account_last" -v branch="$account_branch" '
    /^## Current Point$/ {
      print "## 2026-10-12 — Selected history"
      print "- **Category:** testing"
      print "- **Status:** Completed"
      print "- **What / why:** Account for the selected history."
      print "<details>"
      print "<summary>Technical details and commit evidence</summary>"
      print "- **Important files:** none"
      print "- **Commits:** " ids
      print "- **Junior notes:** None."
      print "- **Verification:** not run"
      print "</details>"
      print "- **Impact:** History represented."
      print
      print "- **HEAD:** `" latest "` on `" branch "`"
      print "- **Recap checkpoint:** `" latest "`"
      print "- **Pending committed history:** None"
      print "- **Committed work:** " note
      print "- **Uncommitted work:** None."
      print "- **Next safe point:** None identified."
      next
    }
    /^- \*\*(HEAD|Recap checkpoint|Pending committed history|Committed work|Uncommitted work|Next safe point):\*\*/ {next}
    /^last_commit: / {print "last_commit: " latest; next}
    /^history_head: / {print "history_head: " latest; next}
    /^pending_commits: / {print "pending_commits: none"; next}
    /^output_sha256: / {next}
    {print}
  ' "$account_prior" > "$fixture/account-unsigned"
  draft_hash="$( (sha256sum "$fixture/account-unsigned" 2>/dev/null || shasum -a 256 "$fixture/account-unsigned") | awk 'NR==1 {print $1}')"
  awk -v hash="$draft_hash" '/^-->$/ {print "output_sha256: " hash} {print}' "$fixture/account-unsigned" > "$account_draft"
}
reject_account_draft() {
  local error
  if error="$(bash "$skill/scripts/validate-recap.sh" "$account_repo" "$account_draft" "$fixture/account-selected" "$account_last" "$account_prior" 2>&1)"; then
    echo 'Validator accepted missing or repeated selected ID outside dated entries' >&2; exit 1
  fi
  [[ "$error" == *'selected commits missing'* ]] || { printf 'Wrong rejection: %s\n' "$error" >&2; exit 1; }
  [[ "$(git -C "$account_repo" hash-object "$account_prior")" == "$account_before" ]] || exit 1
  [[ "$(awk '/^last_commit: / {print $2}' "$account_prior")" == "$account_base" ]] || exit 1
}
make_account_draft "\`$account_first\` \`$account_second\`" "New commit \`$account_last\` appears only here."
reject_account_draft
make_account_draft "\`$account_first\` \`$account_last\`" "The middle commit \`$account_second\` is only here."
reject_account_draft
make_account_draft "\`$account_first\` \`$account_second\` \`$account_last\` \`$account_last\`" 'All work is documented.'
reject_account_draft
make_account_draft "\`$account_first\` \`$account_second\` \`$account_last\`" 'All work is documented.'
bash "$skill/scripts/validate-recap.sh" "$account_repo" "$account_draft" "$fixture/account-selected" "$account_last" "$account_prior"
[[ "$(git -C "$account_repo" hash-object "$account_prior")" == "$account_before" ]] || exit 1

# A caught-up publication must still pin its history head to captured HEAD.
account_stale_head_unsigned="$fixture/account-stale-head-unsigned"
awk -v stale="$account_second" '
  /^history_head: / {print "history_head: " stale; next}
  /^output_sha256: / {next}
  {print}
' "$account_draft" > "$account_stale_head_unsigned"
account_stale_head_hash="$( (sha256sum "$account_stale_head_unsigned" 2>/dev/null || shasum -a 256 "$account_stale_head_unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$account_stale_head_hash" '/^-->$/ {print "output_sha256: " hash} {print}' \
  "$account_stale_head_unsigned" > "$fixture/account-stale-head"
if stale_head_error="$(bash "$skill/scripts/validate-recap.sh" "$account_repo" "$fixture/account-stale-head" "$fixture/account-selected" "$account_last" "$account_prior" 2>&1)"; then
  echo 'Validator accepted a caught-up recap with stale history_head' >&2; exit 1
fi
[[ "$stale_head_error" == *'history head does not match captured HEAD'* ]] ||
  { printf 'Wrong stale history-head rejection: %s\n' "$stale_head_error" >&2; exit 1; }

# A partial recap must preserve the exact oldest-first remainder, not just its
# count, so later invocations cannot skip or duplicate queued history.
for ((n=4; n<=102; n++)); do git -C "$account_repo" commit --allow-empty -qm "pending $n"; done
account_head="$(git -C "$account_repo" rev-parse HEAD)"
account_legacy_prior="$fixture/account-legacy-prior"
cat > "$fixture/account-legacy-unsigned" <<DOC
# Project Recap
## Scope
- **Committed range:** through $account_base.
## 2026-10-10 — Published checkpoint
- **Category:** testing
- **Status:** Completed
- **What / why:** Preserved prior work.
- **Important files:** none
- **Commits:** \`$account_base\`
- **Impact:** Checkpoint documented.
- **Junior notes:** None.
- **Verification:** not run
## Current Point
- **HEAD:** \`$account_head\` on \`$account_branch\`
- **Recap checkpoint:** \`$account_base\`
- **Pending committed history:** 102 commits remain; oldest unrepresented: \`$account_first\`
- **Committed work:** Earlier entry.
- **Uncommitted work:** None.
- **Verification:** not run
- **Next safe point:** Account for pending work.
<!-- recap-state
branch: $account_branch
last_commit: $account_base
last_updated: 2026-10-10
-->
DOC
account_legacy_hash="$( (sha256sum "$fixture/account-legacy-unsigned" 2>/dev/null || shasum -a 256 "$fixture/account-legacy-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$account_legacy_hash" '/^-->$/ {print "output_sha256: " hash} {print}' \
  "$fixture/account-legacy-unsigned" > "$account_legacy_prior"
account_full_history="$fixture/account-full-history"
git -C "$account_repo" rev-list --topo-order --reverse "$account_base..$account_head" > "$account_full_history"
account_partial_selected="$fixture/account-partial-selected"
awk 'NR<=100' "$account_full_history" > "$account_partial_selected"
account_partial_checkpoint="$(awk 'NR==100 {print; exit}' "$account_full_history")"
account_next_unrepresented="$(awk 'NR==101 {print; exit}' "$account_full_history")"
account_remaining_queue="$(awk 'NR>100 {printf "%s%s", separator, $0; separator=" "} END {print ""}' "$account_full_history")"
account_selected_inline="$(awk '{printf "%s`%s` — selected commit", separator, $0; separator="; "}' "$account_partial_selected")"
account_partial_draft="$fixture/account-partial-draft"
cat > "$fixture/account-partial-unsigned" <<DOC
# Project Recap
## Scope
- **Committed range:** through $account_base.
## 2026-10-10 — Published checkpoint
- **Category:** testing
- **Status:** Completed
- **What / why:** Preserved prior work.
- **Important files:** none
- **Commits:** \`$account_base\`
- **Impact:** Checkpoint documented.
- **Junior notes:** None.
- **Verification:** not run
## 2026-10-12 — First bounded batch
- **Category:** testing
- **Status:** Completed
- **What / why:** Account for the first bounded batch.
<details>
<summary>Technical details and commit evidence</summary>

- **Important files:** none
- **Commits:** $account_selected_inline
- **Junior notes:** None.
- **Verification:** not run
</details>
- **Impact:** Records the selected history.
## Current Point
- **HEAD:** \`$account_head\` on \`$account_branch\`
- **Recap checkpoint:** \`$account_partial_checkpoint\`
- **Pending committed history:** 2 commits remain; oldest unrepresented: \`$account_next_unrepresented\`
- **Committed work:** The first 100 eligible commits are represented.
- **Uncommitted work:** None.
- **Verification:** not run
- **Next safe point:** Continue with the remaining queue.
<!-- recap-state
branch: $account_branch
last_commit: $account_partial_checkpoint
last_updated: 2026-10-12
history_head: $account_head
pending_commits: $account_remaining_queue
-->
DOC
account_partial_hash="$( (sha256sum "$fixture/account-partial-unsigned" 2>/dev/null || shasum -a 256 "$fixture/account-partial-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$account_partial_hash" '/^-->$/ {print "output_sha256: " hash} {print}' \
  "$fixture/account-partial-unsigned" > "$account_partial_draft"
account_missing_queue_unsigned="$fixture/account-missing-queue-unsigned"
awk '!/^(history_head|pending_commits|output_sha256): /' "$account_partial_draft" > "$account_missing_queue_unsigned"
account_missing_queue_hash="$( (sha256sum "$account_missing_queue_unsigned" 2>/dev/null || shasum -a 256 "$account_missing_queue_unsigned") | awk 'NR==1 {print $1}')"
account_missing_queue="$fixture/account-missing-queue"
awk -v hash="$account_missing_queue_hash" '/^-->$/ {print "output_sha256: " hash} {print}' \
  "$account_missing_queue_unsigned" > "$account_missing_queue"
if queue_error="$(bash "$skill/scripts/validate-recap.sh" "$account_repo" "$account_missing_queue" "$account_partial_selected" "$account_head" "$account_legacy_prior" 2>&1)"; then
  echo 'Validator accepted a partial recap without its remaining commit queue' >&2; exit 1
fi
[[ "$queue_error" == *'remaining history requires pinned pending queue'* ]] ||
  { printf 'Wrong rejection: %s\n' "$queue_error" >&2; exit 1; }
account_wrong_queue_ids="$(printf '%s\n' "$account_remaining_queue" | awk '{print $2, $1}')"
account_wrong_queue_unsigned="$fixture/account-wrong-queue-unsigned"
awk -v wrong="$account_wrong_queue_ids" '/^pending_commits: / {print "pending_commits: " wrong; next} /^output_sha256: / {next} {print}' \
  "$account_partial_draft" > "$account_wrong_queue_unsigned"
account_wrong_queue_hash="$( (sha256sum "$account_wrong_queue_unsigned" 2>/dev/null || shasum -a 256 "$account_wrong_queue_unsigned") | awk 'NR==1 {print $1}')"
account_wrong_queue="$fixture/account-wrong-queue"
awk -v hash="$account_wrong_queue_hash" '/^-->$/ {print "output_sha256: " hash} {print}' \
  "$account_wrong_queue_unsigned" > "$account_wrong_queue"
if queue_error="$(bash "$skill/scripts/validate-recap.sh" "$account_repo" "$account_wrong_queue" "$account_partial_selected" "$account_head" "$account_legacy_prior" 2>&1)"; then
  echo 'Validator accepted a partial recap with an incorrect remaining commit queue' >&2; exit 1
fi
[[ "$queue_error" == *'pending queue does not match remaining history'* ]] ||
  { printf 'Wrong rejection: %s\n' "$queue_error" >&2; exit 1; }
bash "$skill/scripts/validate-recap.sh" "$account_repo" "$account_partial_draft" "$account_partial_selected" "$account_head" "$account_legacy_prior"

# Junior notes are optional in the template, so a candidate may omit them.
account_no_notes_unsigned="$fixture/account-no-notes-unsigned"
awk '/^## 2026-10-12 — First bounded batch$/ {new_entry=1} /^## Current Point$/ {new_entry=0} new_entry && /^- \*\*Junior notes:\*\* / {next} !/^output_sha256: /' "$account_partial_draft" > "$account_no_notes_unsigned"
account_no_notes_hash="$( (sha256sum "$account_no_notes_unsigned" 2>/dev/null || shasum -a 256 "$account_no_notes_unsigned") | awk 'NR==1 {print $1}')"
account_no_notes="$fixture/account-no-notes"
awk -v hash="$account_no_notes_hash" '/^-->$/ {print "output_sha256: " hash} {print}' \
  "$account_no_notes_unsigned" > "$account_no_notes"
if ! bash "$skill/scripts/validate-recap.sh" "$account_repo" "$account_no_notes" "$account_partial_selected" "$account_head" "$account_legacy_prior"; then
  echo 'Validator rejected a recap without optional Junior notes' >&2; exit 1
fi

# An interrupted draft that accounts for one rather than all 1,007 commits
# cannot advance the checkpoint or modify the already published recap.
cp "$expected" "$fixture/incomplete"
printf '%s\n' "$files_commit" >> "$fixture/incomplete"
if bash "$skill/scripts/validate-recap.sh" "$repo" "$recap" "$fixture/incomplete" "$files_commit" "$fixture/old-recap" >/dev/null 2>&1; then
  echo 'Validator accepted incomplete selected history' >&2; exit 1
fi
before="$(git -C "$repo" hash-object "$recap")"
if bash "$skill/scripts/validate-checkpoint.sh" "$repo" "$recap" "$checkpoint" >/dev/null 2>&1; then
  echo 'Checkpoint validator accepted mismatched HEAD' >&2; exit 1
fi
[[ "$(git -C "$repo" hash-object "$recap")" == "$before" ]] || exit 1
printf 'tampered\n' >> "$recap"
if bash "$skill/scripts/validate-recap.sh" "$repo" "$recap" >/dev/null 2>&1; then
  echo 'Validator accepted altered recap' >&2; exit 1
fi
cp "$fixture/signed" "$recap"
# A digest of a draft with a substituted blank line is not the digest
# obtained by deleting the fingerprint field AND its line terminator.
blank_digest="$(awk '/^output_sha256:/ {print ""; next} {print}' "$recap" | (sha256sum 2>/dev/null || shasum -a 256) | awk '{print $1}')"
awk -v hash="$blank_digest" '/^output_sha256:/ {print "output_sha256: " hash; next} {print}' "$recap" > "$fixture/blank-signed"
if bash "$skill/scripts/validate-checkpoint.sh" "$repo" "$fixture/blank-signed" >/dev/null 2>&1; then
  echo 'Validator accepted blank-line fingerprint' >&2; exit 1
fi
# Re-sign an invalid checkpoint so failure is due to history, not its digest.
awk -v bogus="$(printf '%040d' 0)" '/^last_commit:/ {print "last_commit: " bogus; next} /^output_sha256:/ {next} {print}' "$recap" > "$fixture/stale-unsigned"
stale_digest="$( (sha256sum "$fixture/stale-unsigned" 2>/dev/null || shasum -a 256 "$fixture/stale-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$stale_digest" '/^-->$/ {print "output_sha256: " hash} {print}' "$fixture/stale-unsigned" > "$fixture/stale-signed"
if bash "$skill/scripts/validate-checkpoint.sh" "$repo" "$fixture/stale-signed" >/dev/null 2>&1; then
  echo 'Validator accepted signed missing checkpoint' >&2; exit 1
fi
git -C "$repo" checkout -qb other "$checkpoint"
if bash "$skill/scripts/validate-checkpoint.sh" "$repo" "$recap" >/dev/null 2>&1; then
  echo 'Checkpoint validator accepted branch switch' >&2; exit 1
fi
[[ "$(git -C "$repo" hash-object "$recap")" == "$before" ]] || exit 1

mkdir -p "$fixture/not git" "$fixture/empty"
git -C "$fixture/empty" init -q
if bash "$skill/scripts/collect-git-context.sh" "$fixture/not git" >/dev/null 2>&1 || bash "$skill/scripts/collect-git-context.sh" "$fixture/empty" >/dev/null 2>&1; then
  echo 'Collector accepted absent history' >&2; exit 1
fi
# A shallow clone cannot establish an initial oldest-history boundary.
git clone -q --depth 1 "file://$repo" "$fixture/shallow" 2>/dev/null
if bash "$skill/scripts/collect-git-context.sh" "$fixture/shallow" >/dev/null 2>&1; then
  echo 'Collector accepted shallow history' >&2; exit 1
fi
git -C "$repo" checkout -q --detach
if bash "$skill/scripts/collect-git-context.sh" "$repo" >/dev/null 2>&1; then
  echo 'Collector accepted detached HEAD' >&2; exit 1
fi
printf 'Recap shell scenarios passed.\n'
