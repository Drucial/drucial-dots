---
name: api
description: Server action or API route workflow. Enforces validation, error shape, revalidation, and TanStack Query hook wrapping.
argument-hint: "[action or route description]"
disable-model-invocation: true
---

Build a server action or API route. $ARGUMENTS describes the operation. Use server action by default; only use a route if the spec calls for an external HTTP API.

## Step 1: Plan

Identify:
- **Inputs** and their Zod schema.
- **Output shape**: `{ ok: true; data: T } | { ok: false; error: string }`.
- **Side effects**: what gets read/written, what paths/tags to revalidate.
- **Auth requirements**: who can call this? Check session/role at the top.

Confirm with user.

## Step 2: Implement the action

File: `lib/actions/{domain}.ts` (or follow the project's existing convention — check first).

Per `rules/backend.md`:
1. `"use server"` at top.
2. Zod schema in-file (or imported from `lib/validations.ts`).
3. Auth check (if applicable).
4. `safeParse` → return early on failure.
5. Try/catch around DB call → log error, return user-safe message.
6. `revalidatePath` / `revalidateTag` after mutations.
7. Return discriminated union.

## Step 3 (optional but usually): TanStack Query hook

If this action is consumed by client components, write the matching hook in `hooks/{domain}/use-{verb}-{thing}.ts` per `rules/data-layer.md`:

- Mutations: `useMutation` + `invalidateQueries` on success.
- Queries: `useQuery` with proper `queryKey`.

## Step 4: Tests

Co-located in `__tests__/`. Test:
- Validation rejects bad input.
- Success path returns `{ ok: true, ... }`.
- DB error returns `{ ok: false, ... }`.

## Step 5: Verify

- `pnpm typecheck`
- `pnpm lint`
- Run new tests.

## Rules

- For sensitive actions (auth, billing, admin): also delegate to `@security-reviewer` (or whichever security agent we have) before commit.
- Don't skip the auth check on mutating actions just because the route is "internal" — actions are callable from anywhere with the right import path.
