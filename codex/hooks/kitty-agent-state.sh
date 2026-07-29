#!/usr/bin/env bash
set -uo pipefail

[[ -n "${KITTY_WINDOW_ID:-}" && -n "${KITTY_LISTEN_ON:-}" ]] || exit 0
event="${1:-}"
payload="$(cat 2>/dev/null || true)"
project="$PWD"
if command -v jq >/dev/null 2>&1 && [ -n "$payload" ]; then
  from_payload="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null || true)"
  [ -z "$from_payload" ] || project="$from_payload"
fi
project="$(basename "$project")"

case "$event" in
  SessionStart|UserPromptSubmit|PostToolUse) color="#9ccfd8"; title="● $project" ;;
  PermissionRequest) color="#eb6f92"; title="● $project" ;;
  Stop) color="#a6e3a1"; title="● $project" ;;
  SessionEnd) color="NONE"; title="" ;;
  *) exit 0 ;;
esac

kitty @ --to "$KITTY_LISTEN_ON" set-tab-title --match "window_id:$KITTY_WINDOW_ID" "$title" >/dev/null 2>&1
kitty @ --to "$KITTY_LISTEN_ON" set-tab-color --match "window_id:$KITTY_WINDOW_ID" active_fg="$color" inactive_fg="$color" >/dev/null 2>&1
exit 0
