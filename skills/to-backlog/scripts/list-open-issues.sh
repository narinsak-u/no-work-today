#!/usr/bin/env bash
set -euo pipefail

root="${1:-}"
if [[ -z "$root" || ! -d "$root" ]]; then
  printf 'list-open-issues: repository directory unavailable\n' >&2
  exit 1
fi
root="$(cd "$root" && pwd -P)"
if ! command -v gh >/dev/null 2>&1; then
  printf 'list-open-issues: GitHub CLI unavailable; issue coverage is incomplete\n' >&2
  exit 1
fi
response="$(mktemp)"
trap 'rm -f "$response"' EXIT
if ! (cd "$root" && gh api --paginate \
  --jq '.[] | select(.pull_request == null) | {number, title, body, labels: [.labels[]?.name], url: .html_url}' \
  'repos/{owner}/{repo}/issues?state=open&per_page=100') > "$response"; then
  printf 'list-open-issues: GitHub issue fetch failed; issue coverage is incomplete\n' >&2
  exit 1
fi
cat "$response"
