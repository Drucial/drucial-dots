#!/usr/bin/env bash
# Test for check-primitives.sh
set -euo pipefail

HOOK="$HOME/Dev/drucial-dots/claude/hooks/check-primitives.sh"
TMP="$(mktemp -d)"
mkdir -p "$TMP/components/ui"
touch "$TMP/components/ui/badge.tsx"
touch "$TMP/.git"  # mark as project root

# Test 1: writing a "pill" file should nudge (badge exists)
input='{"tool_name":"Write","tool_input":{"file_path":"'$TMP'/components/ui/pill.tsx"}}'
output="$(echo "$input" | "$HOOK" 2>&1 1>/dev/null || true)"
if echo "$output" | grep -q "Existing primitive"; then
  echo "✓ Test 1 passed: pill triggered nudge"
else
  echo "✗ Test 1 FAILED: expected nudge, got: $output"
  exit 1
fi

# Test 2: writing an unrelated file should not nudge
input='{"tool_name":"Write","tool_input":{"file_path":"'$TMP'/components/ui/data-table.tsx"}}'
output="$(echo "$input" | "$HOOK" 2>&1 1>/dev/null || true)"
if [[ -z "$output" ]]; then
  echo "✓ Test 2 passed: data-table did not nudge"
else
  echo "✗ Test 2 FAILED: unexpected output: $output"
  exit 1
fi

# Test 3: editing (not writing) should not fire
input='{"tool_name":"Edit","tool_input":{"file_path":"'$TMP'/components/ui/pill.tsx"}}'
output="$(echo "$input" | "$HOOK" 2>&1 1>/dev/null || true)"
if [[ -z "$output" ]]; then
  echo "✓ Test 3 passed: Edit did not fire"
else
  echo "✗ Test 3 FAILED: unexpected output: $output"
  exit 1
fi

rm -rf "$TMP"
echo "All tests passed."
