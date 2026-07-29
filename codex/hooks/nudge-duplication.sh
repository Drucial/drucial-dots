#!/usr/bin/env bash
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hook-lib.sh
source "$DIR/hook-lib.sh"
command -v jq >/dev/null 2>&1 || exit 0
codex_hook_input
CODEX_HOOK_CWD="$(printf '%s' "$CODEX_HOOK_INPUT" | jq -r '.cwd // empty')"
[ -n "$CODEX_HOOK_CWD" ] || CODEX_HOOK_CWD="$PWD"

messages=""
while IFS= read -r path; do
  file="$(codex_absolute_path "$path")"
  [ -f "$file" ] || continue
  case "$file" in *.ts|*.tsx|*.js|*.jsx) ;; *) continue ;; esac
  dupes="$(grep -oE 'className="[^"]+"' "$file" 2>/dev/null |
    awk -F'"' '{ if (split($2, a, " ") >= 4) print $0 }' |
    sort | uniq -c | awk '$1 >= 3 {print $0}' | head -3 || true)"
  [ -z "$dupes" ] || messages="${messages}Repeated JSX/class patterns in $path are extraction candidates. "
done < <(codex_patch_paths)

if [ -n "$messages" ]; then
  printf '{"systemMessage":"%s"}\n' "$messages"
fi
exit 0
