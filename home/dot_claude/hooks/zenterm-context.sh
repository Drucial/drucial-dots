#!/bin/bash
# SessionStart hook: when Claude runs in a live ZenTerm pane, say so and point it at the zen CLI.

[ -n "$ZEN_CONTROL_SOCK" ] || exit 0
command -v zen >/dev/null 2>&1 || exit 0
zen --socket "$ZEN_CONTROL_SOCK" hello >/dev/null 2>&1 || exit 0

cat <<'EOF'
This session runs inside ZenTerm, the user's terminal. The `zen` CLI controls it (`zen --help`). For worktree work, use `zen worktree` instead of `git worktree` or EnterWorktree.
EOF
