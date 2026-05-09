---
name: feature
description: Multi-file feature workflow with mental-model checkpoint. Use for anything touching components + logic + data.
argument-hint: "[feature description]"
disable-model-invocation: true
---

Build a feature with explicit tri-layer separation. $ARGUMENTS describes the feature.

## Step 1: Mental-model checkpoint

Before writing code, identify and confirm:

- **UI layer**: which components? new or extending existing? Grep `components/ui/` for primitives we can reuse.
- **Logic layer**: what pure functions / business rules / transforms? Where do they live (`utils/` or `lib/`)?
- **Data layer**: what data is read / mutated? Server action(s)? TanStack Query hook(s)?

Present this breakdown to the user with `AskUserQuestion`. Wait for confirmation or correction before any edits.

## Step 2: Plan the changes

For each layer, list the exact files to create or modify:

```
UI:
  - components/views/{feature}/{name}.tsx (new)
  - app/(routes)/{path}/page.tsx (modify)

Logic:
  - lib/{feature}/{helper}.ts (new)

Data:
  - lib/actions/{feature}.ts (new server action)
  - hooks/{feature}/use-{thing}.ts (new TanStack hook)

Tests:
  - lib/{feature}/__tests__/{helper}.test.ts
  - hooks/{feature}/__tests__/use-{thing}.test.ts
```

Confirm with user before editing.

## Step 3: Build outside-in (data → logic → UI)

1. Schema/types first (if DB shape changes).
2. Server action with Zod validation (per `rules/backend.md`).
3. TanStack Query hook wrapping the action (per `rules/data-layer.md`).
4. Pure logic helpers in `lib/{feature}/` if needed.
5. UI components, composing existing primitives (per `rules/reuse.md`).

After each layer, run `pnpm typecheck` to catch issues early.

## Step 4: Tests

Co-located in `__tests__/` (per `rules/testing.md`). Test the logic layer first (pure functions are easiest). Test hooks with React Testing Library if hooks contain non-trivial logic.

## Step 5: Verify

- `pnpm typecheck`
- `pnpm lint`
- Run the new tests

## Step 6: Hand off

Summarize what was built and what remains. Suggest `/ship` if the feature is complete and tests pass.

## Rules

- Don't skip the mental-model checkpoint. The whole point of this skill is forcing the breakdown.
- For frontend portions, delegate to `@design-ux-architect` (per `rules/frontend.md`).
- For NET-NEW UI primitives, chain `@design-ui-designer` then `@design-ux-architect`.
- Don't bundle unrelated improvements. Stay in-scope.
