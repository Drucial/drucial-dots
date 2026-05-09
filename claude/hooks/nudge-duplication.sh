#!/usr/bin/env bash
# nudge-duplication.sh — PostToolUse on Edit|Write
#
# After an edit, scan the recent diff (or just-modified file) for repeated
# JSX/util patterns. If a pattern appears 3+ times, nudge for extraction.
# Threshold-based to avoid noise.

set -euo pipefail

input="$(cat)"
tool_name="$(echo "$input" | jq -r '.tool_name // empty')"
file_path="$(echo "$input" | jq -r '.tool_input.file_path // empty')"

if [[ "$tool_name" != "Edit" && "$tool_name" != "Write" ]]; then exit 0; fi
if [[ -z "$file_path" || ! -f "$file_path" ]]; then exit 0; fi

# Only scan TS/TSX/JS/JSX
case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx) ;;
  *) exit 0 ;;
esac

# Look for JSX tag patterns repeated 3+ times in the file
# Signal: same opening tag with the same className value 3+ times
matches="$(grep -oE '<[A-Z][A-Za-z]+ className="[^"]{20,}"' "$file_path" 2>/dev/null \
            | sort | uniq -c | awk '$1 >= 3 {print $0}' || true)"

# Also: identical multi-class Tailwind strings 4+ words long, repeated 3+ times
class_dupes="$(grep -oE 'className="[^"]+"' "$file_path" 2>/dev/null \
                | awk -F'"' '{ if (split($2, a, " ") >= 4) print $0 }' \
                | sort | uniq -c | awk '$1 >= 3 {print $0}' || true)"

if [[ -n "$matches" || -n "$class_dupes" ]]; then
  echo "📋 Pattern repeated 3+ times in $file_path — extraction candidate. Run /extract for analysis." >&2
  if [[ -n "$matches" ]]; then
    echo "  JSX repetition:" >&2
    echo "$matches" | head -3 | sed 's/^/    /' >&2
  fi
  if [[ -n "$class_dupes" ]]; then
    echo "  className repetition:" >&2
    echo "$class_dupes" | head -3 | sed 's/^/    /' >&2
  fi
fi

exit 0
