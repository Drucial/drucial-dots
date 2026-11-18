#!/bin/bash
# PostToolUse hook: format the file the agent just edited, using each repo's
# own formatter. Silent no-op when a repo has no formatter for that file type.
# Never touches a file the agent did not edit.

TIMEOUT=10

input=$(cat)

file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file" ] && exit 0

run() {
  if command -v gtimeout >/dev/null 2>&1; then gtimeout "$TIMEOUT" "$@"
  else "$@"
  fi
}

pkg_dir() {
  local d="$1" stop="$2"
  while [ "$d" != "/" ] && [ "$d" != "." ]; do
    [ -f "$d/package.json" ] && { printf '%s' "$d"; return; }
    [ "$d" = "$stop" ] && return
    d=$(dirname "$d")
  done
}

has_prettier() {
  local d="$1"
  [ -n "$(ls "$d"/.prettierrc* "$d"/prettier.config.* 2>/dev/null)" ] && return 0
  [ -f "$d/package.json" ] && grep -q '"prettier"' "$d/package.json"
}

format_one() {
  local file="$1" root d bin
  [ -f "$file" ] || return 0
  root=$(git -C "$(dirname "$file")" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  [ -z "$root" ] && return 0

  case "${file##*.}" in
  ts | tsx | js | jsx | mjs | cjs | json | jsonc | css | scss | md | mdx | yaml | yml | html)
    d=$(pkg_dir "$(dirname "$file")" "$root")
    [ -z "$d" ] && return 0
    has_prettier "$d" || has_prettier "$root" || return 0
    # Direct binary first: `pnpm exec` costs ~1s of startup per edit.
    for bin in "$d/node_modules/.bin/prettier" "$root/node_modules/.bin/prettier"; do
      [ -x "$bin" ] && { (cd "$d" && run "$bin" --write --log-level warn "$file") >/dev/null 2>&1; return 0; }
    done
    (cd "$d" && run pnpm exec prettier --write --log-level warn "$file") >/dev/null 2>&1
    ;;
  go)
    command -v gofmt >/dev/null 2>&1 && run gofmt -w "$file" >/dev/null 2>&1
    ;;
  swift)
    if command -v swift-format >/dev/null 2>&1; then
      run swift-format format --in-place "$file" >/dev/null 2>&1
    elif command -v swift >/dev/null 2>&1; then
      run swift format --in-place "$file" >/dev/null 2>&1
    fi
    ;;
  py)
    if command -v ruff >/dev/null 2>&1; then
      run ruff format "$file" >/dev/null 2>&1
    elif command -v black >/dev/null 2>&1; then
      run black --quiet "$file" >/dev/null 2>&1
    fi
    ;;
  rb)
    [ -f "$root/.rubocop.yml" ] || return 0
    (cd "$root" && run bundle exec rubocop -a --force-exclusion "$file") >/dev/null 2>&1
    ;;
  lua)
    command -v stylua >/dev/null 2>&1 && run stylua "$file" >/dev/null 2>&1
    ;;
  esac
}

format_one "$file"

exit 0
