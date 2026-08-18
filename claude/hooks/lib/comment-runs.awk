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
  printf "marker\t%d\t%d\t0\t1\t%s\n", n, n, sample(l)
}

function flush_run(   cap, kind) {
  if (run_len == 0) return
  cap = 2; kind = "inline"
  # A file header is a doc comment; languages without block syntax still get one.
  if (AT_FILE_TOP && (run_start == 1 || (run_start == 2 && shebang))) { cap = 4; kind = "header" }
  if (run_len > cap && !(ALLOW_LICENSE && run_start <= 5 && is_license(run_buf)))
    printf "%s\t%d\t%d\t%d\t%d\t%s\n", kind, run_start, run_end, cap, run_len, run_first
  run_len = 0; run_end = 0; run_buf = ""; run_first = ""
}

function close_block(end_line) {
  if (block_len > 4 && !(ALLOW_LICENSE && block_start <= 5 && is_license(block_buf)))
    printf "doc\t%d\t%d\t4\t%d\t%s\n", block_start, end_line, end_line - block_start + 1, block_first
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
    run_len++; run_end = NR; run_buf = run_buf "\n" line
    if (has_marker(line)) report_marker(line, NR)
    next
  }

  # A blank line does not end a comment. Two runs under the cap with nothing but
  # air between them are one comment, and the blanks are not counted.
  if (run_len > 0 && line ~ /^[ \t]*$/) next

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
