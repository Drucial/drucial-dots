#!/usr/bin/env bash
# Test for nudge-duplication.sh
set -euo pipefail

HOOK="$HOME/Dev/drucial-dots/claude/hooks/nudge-duplication.sh"
TMP="$(mktemp -d)"

# Test 1: file with repeated JSX should nudge
cat > "$TMP/dup.tsx" <<'EOF'
export function Foo() {
  return (
    <>
      <Badge className="rounded-full bg-zinc-100 px-2 py-0.5 text-xs">A</Badge>
      <Badge className="rounded-full bg-zinc-100 px-2 py-0.5 text-xs">B</Badge>
      <Badge className="rounded-full bg-zinc-100 px-2 py-0.5 text-xs">C</Badge>
    </>
  )
}
EOF

input='{"tool_name":"Edit","tool_input":{"file_path":"'$TMP'/dup.tsx"}}'
output="$(echo "$input" | "$HOOK" 2>&1 1>/dev/null || true)"
if echo "$output" | grep -q "extraction candidate"; then
  echo "✓ Test 1 passed: duplication nudged"
else
  echo "✗ Test 1 FAILED: $output"
  exit 1
fi

# Test 2: file with no duplication should not nudge
cat > "$TMP/clean.tsx" <<'EOF'
export function Bar() {
  return <div>Hello</div>
}
EOF

input='{"tool_name":"Edit","tool_input":{"file_path":"'$TMP'/clean.tsx"}}'
output="$(echo "$input" | "$HOOK" 2>&1 1>/dev/null || true)"
if [[ -z "$output" ]]; then
  echo "✓ Test 2 passed: clean file did not nudge"
else
  echo "✗ Test 2 FAILED: $output"
  exit 1
fi

# Test 3: non-TS file should not fire
echo "# hi" > "$TMP/some.md"
input='{"tool_name":"Edit","tool_input":{"file_path":"'$TMP'/some.md"}}'
output="$(echo "$input" | "$HOOK" 2>&1 1>/dev/null || true)"
if [[ -z "$output" ]]; then
  echo "✓ Test 3 passed: .md skipped"
else
  echo "✗ Test 3 FAILED: $output"
  exit 1
fi

rm -rf "$TMP"
echo "All tests passed."
