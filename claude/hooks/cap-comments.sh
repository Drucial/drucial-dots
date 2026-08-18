#!/usr/bin/env bash
# Enforces the comment caps in rules/code-comments.md on incoming Edit/Write text.
# PreToolUse hook. Emits a deny decision and exits 0. No bypass.

set -uo pipefail

RULES="~/.claude/rules/code-comments.md"

deny() {
  jq -nc --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

command -v jq >/dev/null 2>&1 || deny "jq is required by the comment-cap hook but is not installed."

SCANNER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/comment-runs.awk"
[ -f "$SCANNER" ] || deny "the comment-cap scanner is missing at $SCANNER."

# shellcheck source=lib/comment-style.sh
. "$(dirname "$SCANNER")/comment-style.sh"

INPUT="$(cat)"
TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
TEXT="$(printf '%s' "$INPUT" | jq -r '
  .tool_input.new_string
  // .tool_input.content
  // ([.tool_input.edits[]?.new_string] | join("\n"))
  // empty' 2>/dev/null)"

[ -z "$FILE_PATH" ] && exit 0
[ -z "$TEXT" ] && exit 0

comment_style "$FILE_PATH" || exit 0

# A license header can't be shortened, so it is exempt from the doc cap on Write.
ALLOW_LICENSE=0
[ "$TOOL" = "Write" ] && ALLOW_LICENSE=1

# Located so an edit lower in the file can't claim the header allowance.
AT_FILE_TOP=0
if [ "$TOOL" = "Write" ]; then
  AT_FILE_TOP=1
elif [ -f "$FILE_PATH" ]; then
  OLD="$(printf '%s' "$INPUT" | jq -r '.tool_input.old_string // empty' 2>/dev/null)"
  if [ -n "$OLD" ]; then
    bytes="$(printf '%s' "$OLD" | wc -c | tr -d ' ')"
    # Byte 0, or straight after the shebang, since a header edit skips that line.
    if [ "$(head -c "$bytes" "$FILE_PATH" 2>/dev/null)" = "$OLD" ] \
       || [ "$(tail -n +2 "$FILE_PATH" 2>/dev/null | head -c "$bytes")" = "$OLD" ]; then
      AT_FILE_TOP=1
    fi
  fi
fi


# awk's stderr is left alone: a broken scanner passes every edit, so say so loudly.
if ! VIOLATIONS="$(printf '%s\n' "$TEXT" | awk \
  -v STYLE="$STYLE" \
  -v LINE_RE="$LINE_RE" \
  -v LINE_MARK="$LINE_MARK" \
  -v ALLOW_LICENSE="$ALLOW_LICENSE" \
  -v AT_FILE_TOP="$AT_FILE_TOP" \
  -f "$SCANNER")"; then
  echo "cap-comments: scanner failed, comments in this edit were NOT checked." >&2
  exit 0
fi

[ -z "$VIOLATIONS" ] && exit 0

WHERE="line numbers are within the text you are writing"
[ "$TOOL" = "Write" ] && WHERE="line numbers are within the file"

REASON="Comment cap exceeded in $(basename -- "$FILE_PATH") ($WHERE):"
shown=0
extra=0
TAB="$(printf '\t')"
while IFS="$TAB" read -r kind start end cap count first; do
  [ -z "$kind" ] && continue
  if [ "$shown" -ge 8 ]; then extra=$((extra + 1)); continue; fi
  shown=$((shown + 1))
  case "$kind" in
    inline) what="inline comment run of $count lines, cap is $cap" ;;
    doc)    what="doc comment of $count lines, cap is $cap" ;;
    header) what="file header of $count lines, cap is $cap" ;;
    marker) what="defer marker" ;;
  esac
  if [ "$start" = "$end" ]; then
    REASON="$REASON
  L$start  $what — $first"
  else
    REASON="$REASON
  L$start-L$end  $what — $first"
  fi
done <<EOF
$VIOLATIONS
EOF

[ "$extra" -gt 0 ] && REASON="$REASON
  ...and $extra more"

REASON="$REASON

Shorten or delete them, then retry. Per $RULES: inline comments 2 lines, doc comments 4 lines, no TODO/FIXME/HACK/XXX/TEMP/REMOVEME. A blank line does not start a new comment, so splitting one run into two under the cap counts as one run. Nothing earns an exception — a comment that won't fit means the code needs fixing, not a longer comment."

deny "$REASON"
