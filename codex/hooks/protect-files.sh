#!/usr/bin/env bash
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hook-lib.sh
source "$DIR/hook-lib.sh"
command -v jq >/dev/null 2>&1 || codex_deny "jq is required for file protection hooks but is not installed."
codex_hook_input

while IFS= read -r path; do
  [ -z "$path" ] && continue
  base="$(basename -- "$path" | tr '[:upper:]' '[:lower:]')"
  lower="$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')"
  case "$base" in
    .env|.env.*|*.pem|*.key|*.crt|*.p12|*.pfx|id_rsa|id_ed25519|credentials.json|.npmrc|.pypirc|package-lock.json|yarn.lock|pnpm-lock.yaml|*.gen.ts|*.generated.*|*.min.js|*.min.css)
      codex_deny "Protected file: $path" ;;
  esac
  case "$lower" in
    .git/*|*/.git/*|secrets/*|*/secrets/*)
      codex_deny "Protected path: $path" ;;
    .claude/settings.json|*/.claude/settings.json|.claude/settings.local.json|*/.claude/settings.local.json)
      codex_deny "Claude settings control permissions and hooks. Edit them manually after review." ;;
    .codex/config.toml|*/.codex/config.toml|.codex/hooks.json|*/.codex/hooks.json)
      codex_deny "Codex configuration controls permissions and hooks. Edit it manually after review." ;;
  esac
done < <(codex_patch_paths)

exit 0
