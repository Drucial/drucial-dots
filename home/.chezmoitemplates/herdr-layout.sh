#!/usr/bin/env bash
# Herdr saves resized and toggled blocks, zen-focus's border color and theme picks into the layout; keep those from the live file.
set -euo pipefail
live=$(cat)
repo=$(cat <<'LAYOUT'
{{ include (printf ".chezmoitemplates/herdr-layouts/%s.json" .) | trim }}
LAYOUT
)
printf '%s' "$live" | jq -e . > /dev/null 2>&1 || live='{}'
jq -n --indent 2 --argjson repo "$repo" --argjson live "$live" '
  ([$live | .. | objects | select(has("id")) | {key: .id, value: .}] | from_entries) as $m
  | $repo
  | walk(
      if type == "object" and has("id") and $m[.id] != null then
        (if (has("min") or has("max")) and $m[.id].size != null then .size = $m[.id].size else . end)
        | (if $m[.id] | has("hidden") then .hidden = $m[.id].hidden else del(.hidden) end)
        | (if .content.pane.focus.color? != null and $m[.id].content.pane.focus.color? != null
           then .content.pane.focus.color = $m[.id].content.pane.focus.color else . end)
      else . end)
  | if $live.theme != null then .theme = $live.theme else . end'
