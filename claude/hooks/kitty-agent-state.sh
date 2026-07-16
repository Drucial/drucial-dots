#!/usr/bin/env bash
# kitty-agent-state — reflect this Claude pane's state in the kitty tab title.
#
# Registered on SessionStart, UserPromptSubmit, PostToolUse, Notification, and
# SessionEnd. Prepends a small status dot to THIS Claude pane's tab title and
# tints the tab's text so a glance at the tab bar tells you which project has an
# agent and what it wants:
#   ● blue   agent present / working   (SessionStart, UserPromptSubmit, PostToolUse)
#   ● green  your turn / idle          (Notification: idle_prompt)
#   ● red    blocked on permission     (Notification: permission_prompt)
#   (no dot) no agent                  (SessionEnd)
#
# PostToolUse is the "working" heartbeat: after you approve a permission the agent
# resumes and runs a tool, which flips red back to blue — without it, a red dot
# would hang until your next prompt.
#
# Why a monochrome "●" + a tinted tab foreground rather than a color emoji: the
# kitty tab bar can't color an individual character, and color emoji are
# emoji-width and read chunky. A text-glyph dot stays small; the color comes from
# set-tab-color's active/inactive fg — lighter than a full-tab background wash.
#
# The project name comes from the hook's cwd, so the tab always shows a clean
# label regardless of what Claude writes into its live OSC title.
#
# Deliberately NOT wired to the Stop event: Stop fires whenever Claude ends a
# foreground turn — including when it hands work to a background workflow/task —
# so it false-flagged "your turn" while the agent was still busy. idle_prompt is
# the only event that means "genuinely idle, awaiting you."
#
# No-ops cleanly when Claude runs outside kitty (env vars absent) so it's safe
# to leave registered everywhere.

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
