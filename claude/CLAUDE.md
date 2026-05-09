# Global Claude Code Rules

## Mental Model

- **`components/`** = UI layer (presentation only).
- **`utils/`** + **`lib/`** = Logic (pure functions, transforms, business rules).
- **`hooks/`** + server actions = Data layer (fetching, mutations, state).

Pull logic out of components into utils. Pull data out of components into hooks/server actions. A component that fetches or transforms is doing too much.

## Stack defaults

TypeScript · Next.js (app router) · Tailwind · Drizzle or Prisma · TanStack Query for client-side DB ops · Zod · react-hook-form · Vitest. Detailed conventions live in `rules/`.

## Workflow

- **Plan Before Implementing.** For multi-file features or anything touching event schemas, present a plan and wait for approval before editing.
- **Reuse Before Building.** See `rules/reuse.md`. Grep first.
- **Root-Cause Before Patching.** When a bug persists after one targeted fix, stop and investigate root causes (parent containers for layout, state flow for behavior, type sources for type errors) before more surface fixes.
- **Pre-PR Checklist.** Lint + typecheck must pass; no unused imports/state; scan diff for typos in strings/comments. `/ship` runs this gate automatically.
- **Memory Loop.** When the user corrects a pattern choice (component reuse, file location, naming, library), save it to memory immediately so the correction compounds across sessions.

## Don'ts

- Don't modify generated files (`*.gen.*`, `*.generated.*`).
- Don't bundle tangential improvements into a focused task — mention them separately.
