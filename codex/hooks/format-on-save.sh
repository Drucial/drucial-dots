#!/usr/bin/env bash
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hook-lib.sh
source "$DIR/hook-lib.sh"
command -v jq >/dev/null 2>&1 || exit 0
codex_hook_input
[ "$CODEX_HOOK_MODE" = "plan" ] && exit 0
CODEX_HOOK_CWD="$(printf '%s' "$CODEX_HOOK_INPUT" | jq -r '.cwd // empty')"
[ -n "$CODEX_HOOK_CWD" ] || CODEX_HOOK_CWD="$PWD"

root="$CODEX_HOOK_CWD"
while [ "$root" != "/" ] && [ ! -d "$root/.git" ] && [ ! -f "$root/package.json" ] && [ ! -f "$root/pyproject.toml" ] && [ ! -f "$root/Cargo.toml" ] && [ ! -f "$root/go.mod" ]; do
  root="$(dirname "$root")"
done

while IFS= read -r path; do
  file="$(codex_absolute_path "$path")"
  [ -f "$file" ] || continue
  ext="${file##*.}"
  formatted=false
  if [ -x "$root/node_modules/.bin/biome" ] && { [ -f "$root/biome.json" ] || [ -f "$root/biome.jsonc" ]; }; then
    case "$ext" in js|jsx|ts|tsx|json|css) "$root/node_modules/.bin/biome" format --write "$file" >/dev/null 2>&1 && formatted=true ;; esac
  fi
  if [ "$formatted" = false ] && [ -x "$root/node_modules/.bin/prettier" ]; then
    has_prettier=false
    for config in .prettierrc .prettierrc.json .prettierrc.yml .prettierrc.yaml .prettierrc.js .prettierrc.cjs .prettierrc.mjs .prettierrc.toml prettier.config.js prettier.config.cjs prettier.config.mjs; do
      [ ! -f "$root/$config" ] || has_prettier=true
    done
    if [ "$has_prettier" = true ]; then
      case "$ext" in js|jsx|ts|tsx|json|css|scss|md|yaml|yml|html) "$root/node_modules/.bin/prettier" --write "$file" >/dev/null 2>&1 && formatted=true ;; esac
    fi
  fi
  if [ "$formatted" = false ] && command -v ruff >/dev/null 2>&1; then
    if [ -f "$root/ruff.toml" ] || [ -f "$root/.ruff.toml" ] || { [ -f "$root/pyproject.toml" ] && grep -q '\[tool\.ruff\]' "$root/pyproject.toml"; }; then
      case "$ext" in py) ruff format "$file" >/dev/null 2>&1; ruff check --fix "$file" >/dev/null 2>&1; formatted=true ;; esac
    fi
  fi
  if [ "$formatted" = false ] && command -v rustfmt >/dev/null 2>&1; then
    case "$ext" in rs) rustfmt "$file" >/dev/null 2>&1 && formatted=true ;; esac
  fi
  if [ "$formatted" = false ] && command -v gofmt >/dev/null 2>&1; then
    case "$ext" in go) gofmt -w "$file" >/dev/null 2>&1 && formatted=true ;; esac
  fi
done < <(codex_patch_paths)

exit 0
