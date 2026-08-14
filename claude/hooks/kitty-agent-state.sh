#!/usr/bin/env bash
# Prepends a status dot to this Claude pane's kitty tab and tints the tab text:
# blue working, green your turn, red blocked, no dot when no agent is present.
# PostToolUse is the working heartbeat that flips red back to blue on approval.
# Not on Stop: it fires when work moves to the background and false-flags idle.

set -uo pipefail

# Outside kitty (or remote-control off) there's no tab to label — bail quietly.
[[ -n "${KITTY_WINDOW_ID:-}" && -n "${KITTY_LISTEN_ON:-}" ]] || exit 0

DOT="●"          # small status glyph; try "•" (smaller) or "◆"/"▲" to taste
BLUE="#9ccfd8"   # agent present / working  (rose-pine foam)
GREEN="#a6e3a1"  # your turn / idle          (rose-pine has no green; harmonizing pastel)
LOVE="#eb6f92"   # blocked on permission     (rose-pine love)

event="${1:-}"
payload="$(cat 2>/dev/null || true)"

# Project label = basename of the pane's cwd. Prefer the cwd on the hook payload;
# fall back to the process cwd.
project=""
if command -v jq >/dev/null 2>&1 && [[ -n "$payload" ]]; then
  project="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
fi
[[ -z "$project" ]] && project="$PWD"
project="$(basename "$project")"

# Notification subtype (jq preferred, grep fallback).
notif_type=""
if [[ "$event" == "Notification" && -n "$payload" ]]; then
  if command -v jq >/dev/null 2>&1; then
    notif_type="$(printf '%s' "$payload" | jq -r '.notification_type // .type // empty' 2>/dev/null)"
  fi
  [[ -z "$notif_type" ]] && grep -q 'permission' <<<"$payload" && notif_type="permission_prompt"
fi

case "$event" in
  SessionStart|UserPromptSubmit|PostToolUse) fg="$BLUE" ;;         # present / working
  Notification)
    case "$notif_type" in
      permission_prompt|elicitation_dialog) fg="$LOVE" ;;          # blocked
      *)                                    fg="$GREEN" ;;         # idle_prompt etc.
    esac
    ;;
  SessionEnd) fg="NONE" ;;                                          # agent gone
  *) exit 0 ;;
esac

if [[ "$fg" == "NONE" ]]; then
  title=""                                                         # revert to kitty's auto title
else
  title="$DOT $project"
fi

kitty @ --to "$KITTY_LISTEN_ON" set-tab-title --match "window_id:$KITTY_WINDOW_ID" "$title" >/dev/null 2>&1
kitty @ --to "$KITTY_LISTEN_ON" set-tab-color --match "window_id:$KITTY_WINDOW_ID" \
  active_fg="$fg" inactive_fg="$fg" >/dev/null 2>&1

exit 0
