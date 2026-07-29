---
name: sanity-check
description: Run Drew's light, read-only review over a small focused diff with three parallel finders and one independent verifier. Use only when manually requested for a recently made change, not for a full branch or PR.
---

# Sanity check

Read `~/.claude/skills/sanity-check/SKILL.md` completely and follow it as the canonical workflow with these Codex translations:

- Treat applicable `AGENTS.md` files as equivalent to the `CLAUDE.md` instruction files named by the workflow. Read both when both exist and avoid counting a symlinked copy twice.
- Use Codex collaboration agents: dispatch the three finders concurrently, wait for all results, then dispatch one fresh verifier over the pooled candidates.
- Keep all four agents read-only. Do not edit, build, test, commit, or fix findings.
- At the size gate, recommend Codex `/review` rather than Claude `/code-review`.

Report only independently verified findings and preserve the canonical output format and explicit “Not checked” statement.
