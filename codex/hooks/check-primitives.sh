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
  [ -z "$path" ] && continue
  case "$path" in components/ui/*|*/components/ui/*) ;; *) continue ;; esac
  base="$(basename "$path")"
  base="${base%.tsx}"; base="${base%.ts}"
  synonyms=""
  case "$base" in
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
    *) continue ;;
  esac
  absolute="$(codex_absolute_path "$path")"
  root="$(dirname "$absolute")"
  while [ "$root" != "/" ] && [ ! -e "$root/.git" ] && [ ! -e "$root/package.json" ]; do root="$(dirname "$root")"; done
  for ui in "$root/components/ui" "$root/src/components/ui" "$root/app/components/ui"; do
    [ -d "$ui" ] || continue
    matches="$(find "$ui" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null | grep -Ei "^($synonyms)" | tr '\n' ' ' || true)"
    [ -z "$matches" ] || messages="${messages}Existing primitives match '$base': $matches. Inspect $ui and reuse or extend before adding $path. "
    break
  done
done < <(codex_added_paths)

[ -z "$messages" ] || codex_context "$messages"
exit 0
