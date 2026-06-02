# Global Claude Code Rules

This is the workflow layer — stack-agnostic, applies to every project. Stack
conventions (TS vs Ruby, Next.js vs Rails, ORMs, test runners, formatters)
belong in the project's own `CLAUDE.md`, not here.

## Workflow

- **Plan Before Implementing.** For multi-file features or anything touching schemas, present a plan and wait for approval before editing.
- **Reuse Before Building.** Grep first. See `rules/reuse.md`.
- **Root-Cause Before Patching.** When a bug persists after one targeted fix, stop and investigate root causes (parent containers for layout, state flow for behavior, type sources for type errors) before more surface fixes.
- **Verify Before Claiming Done.** Run the project's typecheck/lint/test commands before reporting a task as complete. Don't claim success from a clean diff alone.
- **Memory Loop.** When the user corrects a pattern choice (component reuse, file location, naming, library), save it to memory immediately so the correction compounds across sessions.

## Code quality

See `rules/code-quality.md` for anti-defaults, naming, and TypeScript-flavored guidance (TS rules are skip-on-mismatch — apply only when the project is TS).

## Copy & content

- **Copy is copy wherever it lives.** User-facing prose is subject to the same
  voice and anti-slop rules whether it sits in a component, a markdown file, or a
  data file. Constants files, content maps, and data objects (e.g. `*-data.ts`,
  `*-copy.ts`, `constants/*`, `content/*`, i18n/locale files, CMS seed data) hold
  real copy — they are not exempt because they look like "data."
- **Include those files in scope for any content work.** When running stop-slop,
  copywriting, or any content-writing agent or skill, sweep the constants/content
  files too. A common miss is editing prose in components while leaving the same
  voice violations untouched in the content map that feeds them.

## Don'ts

- Don't modify generated files (`*.gen.*`, `*.generated.*`).
- Don't bundle tangential improvements into a focused task — mention them separately.
