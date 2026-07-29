#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failed=0
for test in "$DIR"/*.test.sh; do
  echo "=== Running $(basename "$test") ==="
  "$test" || failed=$((failed + 1))
done
[ "$failed" -eq 0 ] || { echo "$failed test file(s) failed."; exit 1; }
echo "All Codex hook tests passed."
