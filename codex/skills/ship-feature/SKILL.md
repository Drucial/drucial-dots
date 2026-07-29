---
name: ship-feature
description: Run Drew's complete feature shipping process in Codex, including checks, draft PR creation, Copilot review, Codex review, triage, fixes, and handoff. Use when a completed feature is ready to ship.
---

# Ship a completed feature

Read `~/.claude/skills/ship-feature/SKILL.md` completely and follow it as the canonical workflow with these Codex translations:

- At the review gate, stop and ask Drew to run `/review`. Do not invoke it yourself or substitute an ordinary self-review.
- Treat `/review` findings as the canonical workflow's `/code-review` findings.
- Use Codex's connected GitHub and Linear capabilities when available; fall back to the documented `gh` commands where connector coverage is insufficient.
- Follow repository-local instructions and a repository-local `ship-feature` adaptation when one exists.

Preserve every gate, especially separate push and ready-for-review actions, explicit finding triage, and the prohibition on merging without direct instruction.
