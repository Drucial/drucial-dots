#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/components/ui"
touch "$TMP/components/ui/badge.tsx" "$TMP/.git"

payload() {
  jq -nc --arg command "$1" --arg cwd "$TMP" '{tool_name:"apply_patch",tool_input:{command:$command},cwd:$cwd,permission_mode:"default"}'
}

deny="$(payload '*** Begin Patch
*** Add File: .env
+SECRET=nope
*** End Patch' | "$DIR/protect-files.sh")"
printf '%s' "$deny" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null

deny="$(payload '*** Begin Patch
*** Add File: src/key.ts
+const key = "ghp_123456789012345678901234567890"
*** End Patch' | "$DIR/scan-secrets.sh")"
printf '%s' "$deny" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null

nudge="$(payload '*** Begin Patch
*** Add File: components/ui/pill.tsx
+export const Pill = () => null
*** End Patch' | "$DIR/check-primitives.sh")"
printf '%s' "$nudge" | jq -e '.hookSpecificOutput.additionalContext | contains("badge.tsx")' >/dev/null

command_payload="$(jq -nc '{tool_name:"Bash",tool_input:{command:"git reset --hard"}}')"
deny="$(printf '%s' "$command_payload" | "$DIR/block-dangerous-commands.sh")"
printf '%s' "$deny" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null

allow="$(jq -nc '{tool_name:"Bash",tool_input:{command:"git status"}}' | "$DIR/block-dangerous-commands.sh")"
[ -z "$allow" ]

echo "Hook behavior tests passed."
