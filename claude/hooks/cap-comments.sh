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

BASE="$(basename -- "$FILE_PATH")"
EXT="$(printf '%s' "$BASE" | tr '[:upper:]' '[:lower:]')"
case "$EXT" in
  *.*) EXT="${EXT##*.}" ;;
  *)   EXT="" ;;
esac

STYLE=""     # block-comment grammar: c | py | rb | lua | hs | html | "" (none)
LINE_RE=""   # awk regex matching a whole-line comment
LINE_MARK="" # literal characters that open a trailing comment

case "$EXT" in
  md|mdx|markdown|txt|rst|adoc|json|jsonc|yaml|yml|toml|csv|tsv|lock|log|svg|env)
    exit 0 ;;
  js|jsx|ts|tsx|mjs|cjs|mts|cts|c|h|cc|cpp|cxx|hpp|hh|cs|java|kt|kts|swift|go|rs|scala|php|dart|m|mm|zig|proto|gradle|groovy|css|scss|less|sass|glsl|frag|vert)
    STYLE=c;    LINE_RE='^[ \t]*//'; LINE_MARK='//' ;;
  py|pyi)
    STYLE=py;   LINE_RE='^[ \t]*#';  LINE_MARK='#' ;;
  rb|rake|gemspec)
    STYLE=rb;   LINE_RE='^[ \t]*#';  LINE_MARK='#' ;;
  sh|bash|zsh|fish|ksh|pl|pm|nix|tf|hcl|ps1|r|jl|ex|exs|cr|mk)
    STYLE="";   LINE_RE='^[ \t]*#';  LINE_MARK='#' ;;
  lua)
    STYLE=lua;  LINE_RE='^[ \t]*--'; LINE_MARK='--' ;;
  sql)
    STYLE=c;    LINE_RE='^[ \t]*--'; LINE_MARK='--' ;;
  hs|elm)
    STYLE=hs;   LINE_RE='^[ \t]*--'; LINE_MARK='--' ;;
  html|htm|vue|svelte|xml|erb|hbs)
    STYLE=html; LINE_RE='';          LINE_MARK='' ;;
  "")
    case "$BASE" in
      Makefile|makefile|GNUmakefile|Dockerfile|Dockerfile.*|Gemfile|Rakefile|Brewfile|Justfile|justfile|Vagrantfile|Procfile|.zshrc|.bashrc|.zshenv|.profile|.gitconfig)
        STYLE=""; LINE_RE='^[ \t]*#'; LINE_MARK='#' ;;
      *) exit 0 ;;
    esac ;;
  *) exit 0 ;;
esac

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

read -r -d '' SCANNER <<'AWK'
function ltrim(s) { sub(/^[ \t]+/, "", s); return s }

function sample(l,   t) {
  t = ltrim(l); gsub(/\t/, " ", t)
  if (length(t) > 60) t = substr(t, 1, 57) "..."
  return t
}

function is_license(b,   lb) {
  lb = tolower(b)
  return (index(lb, "copyright") > 0 || index(lb, "spdx-license-identifier") > 0 || index(lb, "licensed under") > 0)
}

function has_marker(l) {
  return (l ~ /(^|[^A-Za-z0-9_])(TODO|FIXME|HACK|XXX|TEMP|REMOVEME)([^A-Za-z0-9_]|$)/)
}

function is_open(l,   t) {
  t = ltrim(l)
  if (STYLE == "c")    return (substr(t, 1, 2) == "/*")
  if (STYLE == "py")   return (substr(t, 1, 3) == "\"\"\"" || substr(t, 1, 3) == "'''")
  if (STYLE == "rb")   return (substr(t, 1, 6) == "=begin")
  if (STYLE == "lua")  return (substr(t, 1, 4) == "--[[")
  if (STYLE == "hs")   return (substr(t, 1, 2) == "{-")
  if (STYLE == "html") return (substr(t, 1, 4) == "<!--")
  return 0
}

function has_close(l, on_open_line,   rest) {
  if (STYLE == "rb")   return (on_open_line ? 0 : substr(ltrim(l), 1, 4) == "=end")
  if (STYLE == "c")    { rest = on_open_line ? substr(ltrim(l), 3) : l; return index(rest, "*/")    > 0 }
  if (STYLE == "py")   { rest = on_open_line ? substr(ltrim(l), 4) : l; return index(rest, PYDELIM) > 0 }
  if (STYLE == "lua")  { rest = on_open_line ? substr(ltrim(l), 5) : l; return index(rest, "]]")    > 0 }
  if (STYLE == "hs")   { rest = on_open_line ? substr(ltrim(l), 3) : l; return index(rest, "-}")    > 0 }
  if (STYLE == "html") { rest = on_open_line ? substr(ltrim(l), 5) : l; return index(rest, "-->")   > 0 }
  return 0
}

function report_marker(l, n) {
  printf "marker\t%d\t%d\t0\t%s\n", n, n, sample(l)
}

function flush_run(   cap, kind) {
  if (run_len == 0) return
  cap = 2; kind = "inline"
  # A file header is a doc comment; languages without block syntax still get one.
  if (AT_FILE_TOP && (run_start == 1 || (run_start == 2 && shebang))) { cap = 4; kind = "header" }
  if (run_len > cap && !(ALLOW_LICENSE && run_start <= 5 && is_license(run_buf)))
    printf "%s\t%d\t%d\t%d\t%s\n", kind, run_start, run_start + run_len - 1, cap, run_first
  run_len = 0; run_buf = ""; run_first = ""
}

function close_block(end_line) {
  if (block_len > 4 && !(ALLOW_LICENSE && block_start <= 5 && is_license(block_buf)))
    printf "doc\t%d\t%d\t4\t%s\n", block_start, end_line, block_first
  in_block = 0; block_buf = ""
}

{
  line = $0; sub(/\r$/, "", line)

  if (in_block) {
    block_len++; block_buf = block_buf "\n" line
    # A bare opening delimiter names nothing, so borrow the first body line.
    if (block_len == 2 && length(block_first) <= 4) block_first = sample(line)
    if (has_marker(line)) report_marker(line, NR)
    if (has_close(line, 0)) close_block(NR)
    next
  }

  if (NR == 1 && line ~ /^#!/) { shebang = 1; next }

  if (STYLE != "" && is_open(line)) {
    flush_run()
    if (has_marker(line)) report_marker(line, NR)
    if (STYLE == "py") PYDELIM = substr(ltrim(line), 1, 3)
    if (has_close(line, 1)) next
    in_block = 1; block_start = NR; block_len = 1
    block_buf = line; block_first = sample(line)
    next
  }

  if (LINE_RE != "" && line ~ LINE_RE) {
    if (run_len == 0) { run_start = NR; run_first = sample(line) }
    run_len++; run_buf = run_buf "\n" line
    if (has_marker(line)) report_marker(line, NR)
    next
  }

  flush_run()

  # A trailing comment can't break the cap, but its markers still count.
  if (LINE_MARK != "") {
    pos = index(line, LINE_MARK)
    if (pos > 0 && has_marker(substr(line, pos))) report_marker(substr(line, pos), NR)
  }
}

END {
  flush_run()
  if (in_block) close_block(NR)
}
AWK

# awk's stderr is left alone: a broken scanner passes every edit, so say so loudly.
if ! VIOLATIONS="$(printf '%s\n' "$TEXT" | awk \
  -v STYLE="$STYLE" \
  -v LINE_RE="$LINE_RE" \
  -v LINE_MARK="$LINE_MARK" \
  -v ALLOW_LICENSE="$ALLOW_LICENSE" \
  -v AT_FILE_TOP="$AT_FILE_TOP" \
  "$SCANNER")"; then
  echo "cap-comments: scanner failed, comments in this edit were NOT checked." >&2
  exit 0
fi

[ -z "$VIOLATIONS" ] && exit 0

WHERE="line numbers are within the text you are writing"
[ "$TOOL" = "Write" ] && WHERE="line numbers are within the file"

REASON="Comment cap exceeded in $BASE ($WHERE):"
shown=0
extra=0
TAB="$(printf '\t')"
while IFS="$TAB" read -r kind start end cap first; do
  [ -z "$kind" ] && continue
  if [ "$shown" -ge 8 ]; then extra=$((extra + 1)); continue; fi
  shown=$((shown + 1))
  case "$kind" in
    inline) what="inline comment run of $((end - start + 1)) lines, cap is $cap" ;;
    doc)    what="doc comment of $((end - start + 1)) lines, cap is $cap" ;;
    header) what="file header of $((end - start + 1)) lines, cap is $cap" ;;
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

Shorten or delete them, then retry. Per $RULES: inline comments 2 lines, doc comments 4 lines, no TODO/FIXME/HACK/XXX/TEMP/REMOVEME. Nothing earns an exception — a comment that won't fit means the code needs fixing, not a longer comment."

deny "$REASON"
