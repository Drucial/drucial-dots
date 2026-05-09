# Global Claude Code Rules

## TypeScript

- Prefer `type` over `interface`
- Never use `any` — use proper types, `unknown`, or generics
- Avoid type casting (`as`) — fix the root types instead
- Use `import type` for type-only imports
- Remove unused variables and imports entirely — no underscore prefixes to silence warnings

## React & Next.js

- Extract data fetching and mutations into separate hook files
- Extract complex logic into co-located utils files
- Avoid `useEffect` where possible — prefer event callbacks
- One exported component per file; internal helpers are fine
- Write performance-aware code — no unnecessary re-renders, heavy libraries, or runtime allocations
- Next.js: app router only. Default to server components; add `'use client'` only when needed (hooks, event handlers, browser APIs)

## Tailwind

- When a class doesn't apply, check tailwind-merge precedence and parent container constraints before stacking more classes or reaching for `!important`
- Trace layout bugs through the full component tree (parent flex/grid/overflow/height rules) before tweaking the target element

## Code Quality

- Evaluate whether existing code can be simplified or removed before adding new code
- Follow existing project conventions exactly (naming, folder structure, patterns)
- Prefer clear, explicit logic over implicit behavior, hidden state, or dynamic patterns
- Favor DRY — no duplicated logic across files or components
- Use early returns and guard clauses instead of nested ternaries or deep `if` chains

## Workflow

### Reuse Before Building

Before building new UI, grep for existing shared primitives in the current project and compose with them. Only create new components when no existing primitive fits. Never modify shared components without being asked.

### Plan Before Implementing

For multi-file features, tracking/analytics work, or anything involving event schemas, present a plan and wait for approval before editing.

### Root-Cause Before Patching

When a bug persists after one targeted fix, stop and investigate root causes (parent containers for layout, state flow for behavior, type sources for type errors) before attempting more surface fixes.

### Pre-PR Checklist

Before opening a PR: run lint and typecheck, verify no unused imports or state, and scan the diff for typos in strings/comments. Fix pre-existing lint errors in files you touched.

### Architectural Notes

For non-trivial architectural or approach decisions, include a 2-4 bullet tradeoff summary. If you spot improvements outside the current task, mention them separately — don't bundle them into the implementation.
