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

# Every commit in a long delta must be reachable through bounded pages, without duplication.
checkpoint="$head"
for ((n=1; n<=1007; n++)); do git -C "$repo" commit --allow-empty -qm "delta $n"; done
head="$(git -C "$repo" rev-parse HEAD)"
expected="$fixture/expected"
actual="$fixture/actual"
git -C "$repo" rev-list --topo-order --reverse "$checkpoint..$head" > "$expected"
: > "$actual"
for ((offset=0; offset<1007; offset+=100)); do
  page="$(bash "$skill/scripts/collect-git-context.sh" "$repo" "$checkpoint" "$offset" "$head")"
  [[ "$page" == *"total: 1007"* && "$page" == *"offset: $offset"* ]] || exit 1
  count="$(printf '%s\n' "$page" | awk '/^commit: / {n++} END {print n+0}')"
  if ((offset + 100 < 1007)); then
    [[ "$count" == 100 && "$page" == *"has_more: yes"* ]] || exit 1
  else
    [[ "$count" == 7 && "$page" == *"has_more: no"* ]] || exit 1
  fi
  printf '%s\n' "$page" | awk '/^commit: / {print $2}' >> "$actual"
done
cmp "$expected" "$actual"
repeat="$(bash "$skill/scripts/collect-git-context.sh" "$repo" "$head")"
[[ "$repeat" == *"total: 0"* && "$repeat" == *"has_more: no"* ]] || exit 1
if bash "$skill/scripts/collect-git-context.sh" "$repo" "$checkpoint" 0 "$checkpoint" >/dev/null 2>&1; then
  echo 'Collector accepted changed HEAD' >&2; exit 1
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
- **Important files:**
  - \`file 1\` — added in this commit.
- **Commits:** \`$files_commit\`
- **Impact:** Unknown
- **Junior notes:** None.
- **Verification:** not run
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
    { echo 'Unsafe or unexpected recap rejection diagnostic' >&2; exit 1; }
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
bash "$skill/scripts/validate-recap.sh" "$repo" "$recap" "$fixture/selected" "$files_commit" "$fixture/prior-recap"
awk '{printf "%s\r\n", $0}' "$fixture/prior-unsigned" > "$fixture/prior-crlf-unsigned"
prior_crlf_hash="$( (sha256sum "$fixture/prior-crlf-unsigned" 2>/dev/null || shasum -a 256 "$fixture/prior-crlf-unsigned") | awk 'NR==1 {print $1}')"
awk -v hash="$prior_crlf_hash" '{sub(/\r$/, ""); if ($0=="-->") printf "output_sha256: %s\r\n", hash; printf "%s\r\n", $0}' "$fixture/prior-crlf-unsigned" > "$fixture/prior-crlf-recap"
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
      print "- **Important files:** none"
      print "- **Commits:** " ids
      print "- **Impact:** History represented."
      print "- **Junior notes:** None."
      print "- **Verification:** not run"
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
  [[ "$error" == *'selected commits missing or repeated'* ]] || { printf 'Wrong rejection: %s\n' "$error" >&2; exit 1; }
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
