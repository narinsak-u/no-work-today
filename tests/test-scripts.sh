#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
for test_file in "$here"/test-*.sh; do
  if [[ "$test_file" != "$here/test-scripts.sh" ]]; then
    bash "$test_file"
  fi
done
printf 'All shell integration tests passed.\n'
