---
paths:
  - "**/hooks/**"
  - "**/use-*.ts"
  - "**/use-*.tsx"
  - "**/actions.ts"
  - "**/actions/**/*.ts"
  - "**/lib/actions/**"
  - "**/lib/db/**"
  - "**/queries.ts"
  - "**/queries/**"
---

# Data Layer

## Source of truth

- Database access lives in **server actions** (preferred) or centralized query files (`db/queries.ts`). Never call the DB directly from a component.
- ORMs: Drizzle (auranote, reecv-style) or Prisma (praxis-style). Use what the project already has — don't introduce a second one.
- Schema/types are exported from `lib/db/` (or a workspace package). Always import types from there; never duplicate.

## Server actions = mutations + server-fetching

See `rules/backend.md` for action shape.

For server components, call the action (or query helper) directly. No hook wrapping needed.

## Client-side: TanStack Query

All client-side DB ops go through TanStack Query.

### Queries

```ts
// hooks/entries/use-entry.ts
import { useQuery } from "@tanstack/react-query"
import { getEntry } from "@/lib/actions/entries"

export function useEntry(id: string) {
  return useQuery({
    queryKey: ["entries", id],
    queryFn: async () => {
      const result = await getEntry({ id })
      if (!result.ok) throw new Error(result.error)
      return result.data
    },
  })
}
```

### Mutations

```ts
// hooks/entries/use-update-entry.ts
import { useMutation, useQueryClient } from "@tanstack/react-query"
import { updateEntry } from "@/lib/actions/entries"

export function useUpdateEntry() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (input: { id: string; title: string }) => {
      const result = await updateEntry(input)
      if (!result.ok) throw new Error(result.error)
      return result.data
    },
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: ["entries"] })
      qc.invalidateQueries({ queryKey: ["entries", data.id] })
    },
  })
}
```

## queryKey conventions

- Top-level domain: `["entries", ...]`
- Single-resource: `["entries", id]`
- Filtered list: `["entries", { filter: "active", sort: "recent" }]`
- Always invalidate the domain root on mutations to refresh lists.

## Hooks organization

- `hooks/{domain}/use-{thing}.ts` — kebab-case files, camelCase exports.
- Fully typed return values (TanStack Query infers, but export the inferred type if consumers need it).
- One hook per file. Tight focus.
