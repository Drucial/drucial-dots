#!/usr/bin/env bash
# Test for cap-comments.sh
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/cap-comments.sh"
failed=0

run() {
  jq -nc --arg t "$1" --arg f "$2" --arg c "$3" --arg o "${4-}" \
    'if $t == "Write"
       then {tool_name: $t, tool_input: {file_path: $f, content: $c}}
       else {tool_name: $t, tool_input: ({file_path: $f, new_string: $c}
              + (if $o == "" then {} else {old_string: $o} end))} end' \
    | "$HOOK" 2>/dev/null
}

assert_allow() {
  local name="$1" out
  out="$(run "$2" "$3" "$4" "${5-}")"
  if [ -z "$out" ]; then
    echo "✓ $name"
  else
    echo "✗ $name — expected allow, got: $out"
    failed=$((failed + 1))
  fi
}

assert_deny() {
  local name="$1" out
  out="$(run "$2" "$3" "$4" "${5-}")"
  if printf '%s' "$out" | grep -q '"permissionDecision":"deny"'; then
    echo "✓ $name"
  else
    echo "✗ $name — expected deny, got: ${out:-<empty>}"
    failed=$((failed + 1))
  fi
}

assert_allow "2-line inline run passes" Edit /p/a.ts \
'// first line
// second line
const x = 1'

assert_deny "3-line inline run denied" Edit /p/a.ts \
'// first line
// second line
// third line
const x = 1'

assert_allow "4-line doc block passes" Edit /p/a.ts \
'/**
 * Returns the thing.
 * Throws when the thing is absent.
 */
function f() {}'

assert_deny "5-line doc block denied" Edit /p/a.ts \
'/**
 * Returns the thing.
 * Throws when the thing is absent.
 * Mutates nothing.
 */
function f() {}'

assert_allow "single-line block comment passes" Edit /p/a.ts \
'/* short note */
const x = 1'

assert_deny "TODO in a comment denied" Edit /p/a.ts \
'// TODO: wire this up
const x = 1'

assert_deny "TODO trailing a code line denied" Edit /p/a.ts \
'const x = 1; // FIXME later'

assert_allow "TEMP_DIR identifier passes" Edit /p/a.ts \
'const TEMP_DIR = "/tmp";
const XXXL = "size";'

assert_allow "// inside a string is not a comment run" Edit /p/a.ts \
'const a = "https://one.example";
const b = "https://two.example";
const c = "https://three.example";'

# Hash fixtures stay on one physical line so they are not read as comments here.
assert_allow "markdown is skipped" Write /p/readme.md \
$'# Heading\n# Another\n# And another\n# One more'

assert_allow "unknown extension is skipped" Write /p/data.bin \
'// one
// two
// three'

assert_deny "shell 3-line run denied" Edit /p/run.sh \
$'#!/usr/bin/env bash\n# one\n# two\n# three\necho hi'

assert_allow "shebang does not count toward the run" Edit /p/run.sh \
$'#!/usr/bin/env bash\n# one\n# two\necho hi'

assert_deny "python 6-line docstring denied" Edit /p/a.py \
'def f():
    """
    Does a thing.
    Then another thing.
    And a third.
    """
    return 1'

assert_allow "one-line python docstring passes" Edit /p/a.py \
'def f():
    """Does a thing."""
    return 1'

assert_allow "license header exempt on Write" Write /p/a.ts \
'/*
 * Copyright 2026 Someone
 * SPDX-License-Identifier: MIT
 * All rights reserved.
 * Licensed under the MIT License.
 */
const x = 1'

assert_deny "non-license header not exempt on Write" Write /p/a.ts \
'/*
 * Some notes about this file.
 * More notes.
 * Even more notes.
 * Still going.
 */
const x = 1'

# The amend rule: an untouched over-cap comment still rides along in new_string.
assert_deny "over-cap comment carried through an edit denied" Edit /p/a.ts \
'// legacy note line one
// legacy note line two
// legacy note line three
const x = 2'

assert_deny "unterminated over-cap block denied" Edit /p/a.ts \
'/**
 * one
 * two
 * three
 * four'

assert_deny "run split by a blank line denied" Edit /p/a.go \
'// first paragraph line one
// first paragraph line two

// second paragraph line one
// second paragraph line two
func f() {}'

assert_deny "run split by two blank lines denied" Edit /p/a.go \
'// one
// two


// three
func f() {}'

assert_allow "a blank line between comment and code still ends the run" Edit /p/a.go \
'// one
// two

func f() {}

// three
// four
func g() {}'

assert_deny "shell run split by a blank line denied" Edit /p/run.sh \
$'echo hi\n\n# one\n# two\n\n# three\necho bye'

assert_allow "blanks between two 1-line comments pass" Edit /p/a.go \
'// one

// two
func f() {}'

assert_allow "html 4-line comment passes" Edit /p/a.html \
'<!--
  a note
  another
-->
<div></div>'

assert_deny "lua 3-line run denied" Edit /p/a.lua \
'-- one
-- two
-- three
local x = 1'

assert_allow "empty text is skipped" Edit /p/a.ts ''

assert_allow "4-line shell header passes" Write /p/run.sh \
$'#!/usr/bin/env bash\n# one\n# two\n# three\n# four\necho hi'

assert_deny "5-line shell header denied" Write /p/run.sh \
$'#!/usr/bin/env bash\n# one\n# two\n# three\n# four\n# five\necho hi'

assert_deny "mid-file run gets no header allowance" Write /p/run.sh \
$'#!/usr/bin/env bash\necho hi\n\n# one\n# two\n# three\necho bye'

assert_allow "4-line header with no shebang passes" Write /p/a.py \
$'# one\n# two\n# three\n# four\nx = 1'

# The header allowance must not be claimable by an edit further down the file.
TMP="$(mktemp -d)"
printf '#!/usr/bin/env bash\n# one\n# two\necho hi\n' > "$TMP/hdr.sh"

assert_allow "edit at the top of the file gets the header allowance" Edit "$TMP/hdr.sh" \
  $'#!/usr/bin/env bash\n# one\n# two\n# three\n# four' \
  $'#!/usr/bin/env bash\n# one\n# two'

assert_deny "edit below the header claims no allowance" Edit "$TMP/hdr.sh" \
  $'# one\n# two\n# three\necho hi' \
  'echo hi'

rm -rf "$TMP"

if [ "$failed" -gt 0 ]; then
  echo "$failed assertion(s) failed."
  exit 1
fi
echo "All tests passed."
