#!/usr/bin/env bash
# Stop hook. Catches over-cap comments however they were written: cap-comments.sh
# sees Edit and Write, and a heredoc, sed or an editor goes straight past it.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCANNER="$HERE/lib/comment-runs.awk"

command -v jq >/dev/null 2>&1 || exit 0
[ -f "$SCANNER" ] || exit 0

# shellcheck source=lib/comment-style.sh
. "$HERE/lib/comment-style.sh"

INPUT="$(cat)"

# Already blocked once this turn. Blocking again on a report the model could not
# act on is a loop, and the caps are enforced at the edit anyway.
[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Uncommitted work, tracked and new alike. What is committed is somebody's
# decision already; what is in the tree is this session's.
FILES="$( { git diff --name-only HEAD 2>/dev/null
            git ls-files --others --exclude-standard 2>/dev/null; } | sort -u )"
[ -z "$FILES" ] && exit 0

# added is the ranges of lines this working tree adds to a file, as start-end
# pairs. A file git has never seen is added whole.
added() {
  if git ls-files --error-unmatch -- "$1" >/dev/null 2>&1; then
    git diff -U0 HEAD -- "$1" 2>/dev/null |
      awk '/^@@/ { split($3, a, ","); s = substr(a[1], 2) + 0
                   n = (a[2] == "" ? 1 : a[2] + 0)
                   if (n > 0) printf "%d-%d ", s, s + n - 1 }'
    return
  fi
  printf '1-%d ' "$(grep -c '' -- "$1" 2>/dev/null || echo 0)"
}

REPORT=""
found=0

while IFS= read -r file; do
  [ -z "$file" ] && continue
  [ -f "$file" ] || continue
  comment_style "$file" || continue

  ranges="$(added "$file")"
  [ -z "$ranges" ] && continue

  hits="$(awk -v STYLE="$STYLE" -v LINE_RE="$LINE_RE" -v LINE_MARK="$LINE_MARK" \
    -v ALLOW_LICENSE=1 -v AT_FILE_TOP=1 -f "$SCANNER" -- "$file" 2>/dev/null |
    awk -v ADDED="$ranges" -F'\t' '
      BEGIN { n = split(ADDED, r, " ") }
      {
        for (i = 1; i <= n; i++) {
          if (r[i] == "") continue
          split(r[i], p, "-")
          # A run the working tree only part-wrote is still a run it touched.
          if ($2 <= p[2] && $3 >= p[1]) { print; break }
        }
      }')"
  [ -z "$hits" ] && continue

  TAB="$(printf '\t')"
  while IFS="$TAB" read -r kind start end cap count first; do
    [ -z "$kind" ] && continue
    found=$((found + 1))
    [ "$found" -gt 10 ] && continue
    case "$kind" in
      inline) what="inline comment run of $count lines, cap is $cap" ;;
      doc)    what="doc comment of $count lines, cap is $cap" ;;
      header) what="file header of $count lines, cap is $cap" ;;
      marker) what="defer marker" ;;
    esac
    REPORT="$REPORT
  $file:$start-$end  $what — $first"
  done <<EOF
$hits
EOF
done <<EOF
$FILES
EOF

[ "$found" -eq 0 ] && exit 0
[ "$found" -gt 10 ] && REPORT="$REPORT
  ...and $((found - 10)) more"

jq -nc --arg r "Comment cap exceeded in the working tree:
$REPORT

These are comments this session wrote or edited, found by reading the files
rather than the edits, so a heredoc or a sed does not get past. Shorten or
delete them. Per ~/.claude/rules/code-comments.md: inline comments 2 lines,
block doc comments 4, no TODO/FIXME/HACK/XXX/TEMP/REMOVEME. A blank line does
not start a new comment. Nothing earns an exception — a comment that will not
fit means the code needs fixing, not a longer comment." \
  '{decision:"block", reason:$r}'
