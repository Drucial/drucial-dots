---
paths:
  - "**/app/api/**"
  - "**/route.ts"
  - "**/actions.ts"
  - "**/actions/**/*.ts"
  - "**/lib/actions/**"
  - "**/server/**/*.ts"
---

# Backend

## Server action shape

Every server action follows this shape:

```ts
"use server"

import { z } from "zod"
import { revalidatePath } from "next/cache"
import { db } from "@/lib/db"

const updateEntrySchema = z.object({
  id: z.string().uuid(),
  title: z.string().min(1).max(200),
})

export type UpdateEntryResult =
  | { ok: true; data: Entry }
  | { ok: false; error: string }

export async function updateEntry(input: unknown): Promise<UpdateEntryResult> {
  const parsed = updateEntrySchema.safeParse(input)
  if (!parsed.success) {
    return { ok: false, error: "Invalid input" }
  }

  try {
    const entry = await db.update(entries).set(parsed.data).where(eq(entries.id, parsed.data.id)).returning().get()
    revalidatePath(`/entries/${entry.id}`)
    return { ok: true, data: entry }
  } catch (e) {
    console.error("updateEntry failed", e)
    return { ok: false, error: "Update failed" }
  }
}
```

## Required structure

1. `"use server"` directive at top.
2. Zod schema defined inside the file (or imported from `lib/validations.ts`).
3. Discriminated union return type — `{ ok: true; data: ... } | { ok: false; error: string }`.
4. `safeParse` at the top, return early on validation failure.
5. Try/catch around the DB call. Log unexpected errors; return user-safe message.
6. `revalidatePath` or `revalidateTag` after mutations.

## Naming

- Verb-first action names: `getEntry`, `createEntry`, `updateEntry`, `deleteEntry`, `listEntries`.
- File names: `lib/actions/{domain}.ts` (auranote-style) or `actions/{domain}.ts` (praxis-style). Match the project's existing layout.

## API routes

- Use server actions over API routes for app-internal mutations. API routes are for: external webhooks, third-party integrations, REST endpoints consumed by non-Next clients.
- API routes use the same return-shape discipline (`NextResponse.json({ ok, data | error })`).

## What never goes in backend code

- UI logic (JSX, Tailwind classes, browser-only APIs).
- React imports.
- `'use client'` files calling server-side APIs directly.
