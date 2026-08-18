#!/usr/bin/env bash
# Test for check-comment-diff.sh
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/check-comment-diff.sh"
failed=0

# A throwaway repo per case, so what counts as added is the case's own doing.
repo() {
  local d
  d="$(mktemp -d)"
  git -C "$d" init -q
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  printf '%s' "$d"
}

commit() {
  printf '%s\n' "$2" > "$1/$3"
  git -C "$1" add -A
  git -C "$1" commit -qm x
}

run() {
  ( cd "$1" && printf '{}' | "$HOOK" 2>/dev/null )
}

assert_block() {
  local name="$1" out
  out="$(run "$2")"
  if printf '%s' "$out" | grep -q '"decision":"block"'; then
    echo "✓ $name"
  else
    echo "✗ $name — expected block, got: ${out:-<empty>}"
    failed=$((failed + 1))
  fi
  rm -rf "$2"
}

assert_pass() {
  local name="$1" out
  out="$(run "$2")"
  if [ -z "$out" ]; then
    echo "✓ $name"
  else
    echo "✗ $name — expected pass, got: $out"
    failed=$((failed + 1))
  fi
  rm -rf "$2"
}

# The whole point: a run written by something that is not Edit or Write.
d="$(repo)"
cat > "$d/a.go" <<'EOF'
package a

// one
// two
// three
func f() {}
EOF
assert_block "an over-cap run in an untracked file is caught" "$d"

d="$(repo)"
commit "$d" 'package a' a.go
cat > "$d/a.go" <<'EOF'
package a

// one
// two
// three
func f() {}
EOF
assert_block "an over-cap run added to a tracked file is caught" "$d"

# The reason this is not the pre-commit hook run over whole files.
d="$(repo)"
commit "$d" 'package a

// one
// two
// three
func old() {}' a.go
printf 'package a\n\n// one\n// two\n// three\nfunc old() {}\n\nfunc added() {}\n' > "$d/a.go"
assert_pass "a legacy over-cap run nobody touched is left alone" "$d"

d="$(repo)"
commit "$d" 'package a

// one
// two
// three
func old() {}' a.go
printf 'package a\n\n// one\n// two\n// three EDITED\nfunc old() {}\n' > "$d/a.go"
assert_block "editing one line of a legacy run makes it yours" "$d"

d="$(repo)"
cat > "$d/a.go" <<'EOF'
package a

// one
// two
func f() {}
EOF
assert_pass "a run inside the cap passes" "$d"

d="$(repo)"
cat > "$d/notes.md" <<'EOF'
<!-- one
two
three
four
five -->
EOF
assert_pass "a file type the rule does not govern is skipped" "$d"

d="$(repo)"
cat > "$d/a.go" <<'EOF'
package a

// TODO: come back to this
func f() {}
EOF
assert_block "a defer marker is caught" "$d"

d="$(repo)"
commit "$d" 'package a' a.go
assert_pass "a clean tree passes" "$d"

d="$(mktemp -d)"
assert_pass "somewhere that is not a repo passes" "$d"

d="$(repo)"
cat > "$d/a.go" <<'EOF'
package a

// one
// two
// three
func f() {}
EOF
out="$( cd "$d" && printf '{"stop_hook_active":true}' | "$HOOK" 2>/dev/null )"
if [ -z "$out" ]; then
  echo "✓ a second stop in the same turn does not block again"
else
  echo "✗ a second stop in the same turn does not block again — got: $out"
  failed=$((failed + 1))
fi
rm -rf "$d"

if [ "$failed" -eq 0 ]; then
  echo "All tests passed."
else
  echo "$failed assertion(s) failed."
  exit 1
fi
