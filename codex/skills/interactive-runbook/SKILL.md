---
name: interactive-runbook
description: Run Drew's manual verification interactively in Codex, one check and one observation at a time. Use when Drew asks to run, execute, walk through, or complete a runbook; or when a shipping flow reaches live GUI, filesystem, Git, browser, device, focus, layout, motion, or timing verification.
---

# Run an interactive runbook

Read `~/.claude/skills/interactive-runbook/SKILL.md` completely and follow it as the canonical workflow.

Use Codex commentary for each instruction or controlled fixture change, then stop and wait for Drew's observation before advancing. Never collapse multiple checks into one turn, infer a pass from silence, or substitute `drive-dev-app`.

Follow repository-local instructions and a repository-local `interactive-runbook` adaptation when one exists.
