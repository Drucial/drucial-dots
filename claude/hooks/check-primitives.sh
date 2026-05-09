#!/usr/bin/env bash
# check-primitives.sh — PreToolUse on Edit|Write
#
# When Claude is about to write a NEW component file in components/ui/, scan
# the existing components/ui/ for primitives that match common synonyms.
# If matches found, return a system message nudging reuse. NOT a block.

set -eo pipefail

# Read JSON from stdin
input="$(cat)"
tool_name="$(echo "$input" | jq -r '.tool_name // empty')"
file_path="$(echo "$input" | jq -r '.tool_input.file_path // empty')"

# Only fire on Write to components/ui/ creating a new file
if [ "$tool_name" != "Write" ]; then exit 0; fi
case "$file_path" in
  */components/ui/*) ;;
  *) exit 0 ;;
esac

# Extract proposed primitive name from filename (strip path, ext, .tsx/.ts)
basename="$(basename "$file_path" .tsx)"
basename="$(basename "$basename" .ts)"

# Map concept → regex of synonyms (bash 3.2 compatible — no associative arrays)
synonyms=""
case "$basename" in
  *pill*|*badge*|*chip*|*tag*|*label*) synonyms="pill|badge|chip|tag|label" ;;
  *button*|*btn*|*cta*) synonyms="button|btn|cta" ;;
  *card*|*panel*|*tile*) synonyms="card|panel|tile" ;;
  *modal*|*dialog*|*sheet*|*drawer*|*overlay*) synonyms="modal|dialog|sheet|drawer|overlay" ;;
  *tooltip*|*hint*|*popover*) synonyms="tooltip|hint|popover" ;;
  *dropdown*|*menu*|*select*) synonyms="dropdown|menu|select" ;;
  *toast*|*alert*|*notification*|*snackbar*) synonyms="toast|alert|notification|snackbar" ;;
  *avatar*|*profile-pic*|*profile-image*) synonyms="avatar|profile-pic|profile-image" ;;
  *skeleton*|*placeholder*|*loader*|*spinner*|*loading*) synonyms="skeleton|placeholder|loader|spinner|loading" ;;
  *input*|*field*|*textbox*|*textarea*|*textfield*) synonyms="input|field|textbox|textarea|textfield" ;;
  *) exit 0 ;;
esac

# Find project root (look upward for .git or package.json)
project_root="$(dirname "$file_path")"
while [ "$project_root" != "/" ] && [ ! -e "$project_root/.git" ] && [ ! -e "$project_root/package.json" ]; do
  project_root="$(dirname "$project_root")"
done

ui_dir=""
for candidate in "$project_root/components/ui" "$project_root/src/components/ui" "$project_root/app/components/ui"; do
  if [ -d "$candidate" ]; then ui_dir="$candidate"; break; fi
done

if [ -z "$ui_dir" ]; then exit 0; fi

# Search for matching primitives by filename prefix
matches="$(ls "$ui_dir" 2>/dev/null | grep -E "^($synonyms)" || true)"

if [ -n "$matches" ]; then
  # Print nudge to stderr (surfaced in tool result, not a block).
  flat_matches="$(echo "$matches" | tr '\n' ' ')"
  echo "⚠ Existing primitive(s) match concept of '$basename': $flat_matches" >&2
  echo "  Consider reusing or extending instead of creating $basename." >&2
  echo "  Check $ui_dir before proceeding." >&2
fi

exit 0
