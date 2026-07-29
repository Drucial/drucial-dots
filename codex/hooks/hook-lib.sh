#!/usr/bin/env bash

codex_hook_input() {
  CODEX_HOOK_INPUT="$(cat)"
  CODEX_HOOK_COMMAND="$(printf '%s' "$CODEX_HOOK_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
  CODEX_HOOK_TOOL="$(printf '%s' "$CODEX_HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)"
  CODEX_HOOK_MODE="$(printf '%s' "$CODEX_HOOK_INPUT" | jq -r '.permission_mode // empty' 2>/dev/null || true)"
}

codex_patch_paths() {
  printf '%s\n' "$CODEX_HOOK_COMMAND" |
    sed -nE 's/^\*\*\* (Add|Update|Delete) File: (.*)$/\2/p; s/^\*\*\* Move to: (.*)$/\1/p' |
    awk 'NF && !seen[$0]++'
}

codex_added_paths() {
  printf '%s\n' "$CODEX_HOOK_COMMAND" |
    sed -nE 's/^\*\*\* Add File: (.*)$/\1/p' |
    awk 'NF && !seen[$0]++'
}

codex_absolute_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "${CODEX_HOOK_CWD:-$PWD}" "$1" ;;
  esac
}

codex_deny() {
  local reason="${1//\\/\\\\}"
  reason="${reason//\"/\\\"}"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
  exit 0
}

codex_context() {
  local message="${1//\\/\\\\}"
  message="${message//\"/\\\"}"
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "${2:-PreToolUse}" "$message"
}
