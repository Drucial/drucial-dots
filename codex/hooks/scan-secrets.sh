#!/usr/bin/env bash
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hook-lib.sh
source "$DIR/hook-lib.sh"
command -v jq >/dev/null 2>&1 || exit 0
codex_hook_input

CONTENT="$CODEX_HOOK_COMMAND"
[ -z "$CONTENT" ] && exit 0

matches=""
printf '%s' "$CONTENT" | grep -qE 'AKIA[0-9A-Z]{16}' && matches="$matches AWS access key;"
printf '%s' "$CONTENT" | grep -qiE '(aws_secret_access_key|secret_key)[[:space:]]*[=:][[:space:]]*["'\'']?[A-Za-z0-9/+=]{40}' && matches="$matches AWS secret key;"
printf '%s' "$CONTENT" | grep -qE '(ghp_|gho_|ghs_|ghr_|github_pat_)[a-zA-Z0-9_]{20,}' && matches="$matches GitHub token;"
printf '%s' "$CONTENT" | grep -qE '(sk|rk)[-_][A-Za-z0-9_-]{20,}' && matches="$matches API key;"
printf '%s' "$CONTENT" | grep -qE 'xox[bpras]-[0-9a-zA-Z-]{10,}' && matches="$matches Slack token;"
printf '%s' "$CONTENT" | grep -qE -- '-----BEGIN[[:space:]]+(RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----' && matches="$matches private key;"
printf '%s' "$CONTENT" | grep -qE '(mongodb|postgres|mysql|redis|amqp|smtp)(\+[a-z]+)?://[^:[:space:]]+:[^@[:space:]]+@' && matches="$matches credentialed connection string;"

if [ -n "$matches" ]; then
  codex_deny "Possible secret detected:$matches Move it to an approved secret store or add the fixture manually after review."
fi

if printf '%s' "$CONTENT" | grep -qiE '(password|secret|token|api_key|apikey|api_secret)[[:space:]]*[=:][[:space:]]*["'\''][^"'\'']{8,}["'\'']' &&
  ! printf '%s' "$CONTENT" | grep -qiE '(process\.env|os\.environ|getenv|\$\{|ENV\[|env\()'; then
  codex_context "Possible hardcoded credential detected. Replace it with an environment or secret-store reference; if this is an intentional fixture, have Drew add it manually after review."
fi
exit 0
