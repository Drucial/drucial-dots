#!/usr/bin/env bash
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hook-lib.sh
source "$DIR/hook-lib.sh"
command -v jq >/dev/null 2>&1 || codex_deny "jq is required for command protection hooks but is not installed."
codex_hook_input
COMMAND="$CODEX_HOOK_COMMAND"
[ -z "$COMMAND" ] && exit 0

DEFAULT_BRANCHES="main,master"
if branch="$(git config --get init.defaultBranch 2>/dev/null)" && [ -n "$branch" ]; then
  DEFAULT_BRANCHES="$DEFAULT_BRANCHES,$branch"
fi
PROTECTED_BRANCHES="${CODEX_PROTECTED_BRANCHES:-${CLAUDE_PROTECTED_BRANCHES:-$DEFAULT_BRANCHES}}"
BR_REGEX="$(printf '%s' "$PROTECTED_BRANCHES" | tr ',' '\n' | awk 'NF{printf "%s%s",sep,$0; sep="|"}')"
contains_cmd() { printf '%s' "$COMMAND" | grep -qE "$1"; }
contains_icmd() { printf '%s' "$COMMAND" | grep -qiE "$1"; }

if contains_cmd '(^|[;&|()]+[[:space:]]*)git[[:space:]]+push'; then
  if contains_cmd "git[[:space:]]+push[[:space:]]+[^[:space:]]+[[:space:]]+([^[:space:]]*:)?($BR_REGEX)(\$|[[:space:]])"; then
    codex_deny "Blocked: push to a protected branch. Use a feature branch and open a PR."
  fi
  if contains_cmd 'git[[:space:]]+push[[:space:]]*($|[;&|])'; then
    current="$(git branch --show-current 2>/dev/null || true)"
    if [ -n "$current" ] && printf '%s' ",$PROTECTED_BRANCHES," | grep -q ",$current,"; then
      codex_deny "Blocked: you are on '$current', a protected branch. Switch to a feature branch."
    fi
  fi
  if contains_cmd 'git[[:space:]]+push([[:space:]]+[^[:space:]]+)*[[:space:]]+(-[a-zA-Z]*f[a-zA-Z]*|--force)([[:space:]=]|$)' &&
    ! contains_cmd '\-\-force-with-lease'; then
    codex_deny "Blocked: force push is not allowed. Use --force-with-lease if overwrite is required."
  fi
fi

NO_QUOTES="$(printf '%s' "$COMMAND" | tr -d "'\"")"
if printf '%s' "$NO_QUOTES" | grep -qE 'rm[[:space:]]+(-[a-zA-Z]*[[:space:]]+)*-?[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*[[:space:]]+(/([[:space:]]|\*|$)|~|\$HOME|\$[A-Za-z_][A-Za-z0-9_]*|\.\./\.\.)'; then
  codex_deny "Blocked: recursive force-delete targets a broad or unresolved path."
fi
if printf '%s' "$NO_QUOTES" | grep -qE 'rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*-?[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*[[:space:]]+/(usr|etc|var|bin|sbin|lib|opt|root|boot)([[:space:]/]|$)'; then
  codex_deny "Blocked: recursive delete targets a system directory."
fi
contains_icmd 'DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)[[:space:]]+' && codex_deny "Blocked: destructive SQL DDL detected."
if printf '%s\n' "$COMMAND" | awk 'BEGIN { IGNORECASE=1; RS=";" } /DELETE[[:space:]]+FROM[[:space:]]+[A-Za-z_][A-Za-z0-9_.]*/ && $0 !~ /WHERE/ { bad=1 } END { exit !bad }'; then
  codex_deny "Blocked: DELETE FROM without a WHERE clause."
fi
contains_icmd 'TRUNCATE[[:space:]]+TABLE' && codex_deny "Blocked: TRUNCATE TABLE detected."
if contains_cmd 'chmod([[:space:]]+-[a-zA-Z]+)*[[:space:]]+0?777([[:space:]]|$)' ||
  contains_cmd 'chmod([[:space:]]+-[a-zA-Z]+)*[[:space:]]+a\+rwx([[:space:]]|$)'; then
  codex_deny "Blocked: world-writable permissions detected."
fi
contains_cmd '(curl|wget)[[:space:]].*\|[[:space:]]*(sudo[[:space:]]+)?(bash|sh|zsh|ksh|fish|dash|csh)([[:space:]]|$)' &&
  codex_deny "Blocked: downloaded content piped directly to a shell."
if printf '%s' "$COMMAND" | grep -qE '(^|[^0-9&])>[[:space:]]*/dev/[a-zA-Z][a-zA-Z0-9]*' &&
  ! printf '%s' "$COMMAND" | grep -qE '>[[:space:]]*/dev/(null|stdout|stderr|tty|zero|random|urandom)([[:space:]]|$)'; then
  codex_deny "Blocked: redirection into a raw device file can destroy data."
fi
if contains_cmd '(^|[;&|[:space:]])(mkfs|mkfs\.[a-z0-9]+)([[:space:]]|$)' ||
  contains_cmd '(^|[;&|[:space:]])dd[[:space:]]+[^|]*(if|of)=/dev/[a-zA-Z]'; then
  codex_deny "Blocked: disk command against a device node."
fi
contains_cmd 'git[[:space:]]+reset[[:space:]]+--hard' && codex_deny "Blocked: git reset --hard discards changes."
contains_cmd 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f' && codex_deny "Blocked: git clean -f deletes untracked files."

for pattern in '(npm|yarn|pnpm|bun)[[:space:]]+publish' 'cargo[[:space:]]+publish' 'gem[[:space:]]+push' 'twine[[:space:]]+upload'; do
  if contains_cmd "$pattern" && ! contains_cmd '(^|[[:space:]])(--dry-run|-n)([[:space:]=]|$)'; then
    codex_deny "Blocked: package publishing must run manually or in CI."
  fi
done

exit 0
