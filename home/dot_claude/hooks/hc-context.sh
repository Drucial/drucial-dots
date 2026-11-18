#!/bin/bash
# SessionStart hook: when Claude runs in a live herdr-core terminal, give it its hc address,
# say whether the Herdr app shows it, and set how to run long processes there.

[ -n "$HC_TERMINAL_ID" ] || exit 0
command -v hc >/dev/null 2>&1 || exit 0
info=$(hc get "$HC_TERMINAL_ID" --json 2>/dev/null) || exit 0

# Terminals the Herdr app shows carry its space and tab labels.
shown=""
if command -v jq >/dev/null 2>&1 && [ -n "$(jq -r '.labels["herdr.space"] // empty' <<<"$info" 2>/dev/null)" ]; then
  shown=" The Herdr app shows it as a pane, and terminals you start with \`hc run\` appear under you in its sidebar, where the user can peek at them."
fi

cat <<EOF
This session runs in a herdr-core terminal. Your hc address is \`$HC_TERMINAL_ID\` (\`\$HC_TERMINAL_ID\`); helpers report back with \`hc send $HC_TERMINAL_ID ...\`.$shown

Before your first \`hc\` command this session, load the /hc skill (it has you read \`hc --skill\`, the manual for this version). Preferences:
- Delegate work to helper agents in hc terminals (\`hc run --bg --name <name> --cwd <dir> claude "<task>"\`), not built-in subagents, so the user can watch and steer them. Use a folder Claude already trusts (the repo, or your own cwd) so they don't stall on the trust prompt. Keep built-in subagents for quick lookups.
- Run dev servers, watchers and other long-running processes with \`hc run --bg --name <name> --cwd <repo> -- <command>\`, never your shell tool's background mode, so the user can see them.
- Run slow builds, test suites and CI watches the same way and wait with \`hc wait\`, not sleep or polling.
- Name each terminal after what it runs. Leave dev servers running; remove finished one-off terminals once you have their result. Clean up only terminals you started.
- For the Herdr window itself (layouts, keys, mods), read \`herdr-app --skill\`.
EOF
