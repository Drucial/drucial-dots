#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

failed=0
for test in "$DIR"/*.test.sh; do
  echo "=== Running $(basename "$test") ==="
  if ! "$test"; then
    failed=$((failed + 1))
  fi
done

if [[ "$failed" -gt 0 ]]; then
  echo "$failed test file(s) failed."
  exit 1
fi
echo "All hook tests passed."
