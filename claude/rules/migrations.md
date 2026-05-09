---
paths:
  - "**/migrations/**"
  - "**/drizzle/**"
  - "**/prisma/migrations/**"
  - "**/db/migrate/**"
---

# Database migrations

## Never modify an existing migration

Migrations may have already run in production or staging. Editing one creates drift between environments and can corrupt the migration history. **Always create a new migration** for changes.

## Reversibility

Every migration must be reversible. Implement both directions:
- Drizzle: write the corresponding rollback in a new migration if needed.
- Prisma: prefer additive migrations; for destructive changes, plan a multi-step migration (add new → backfill → switch reads → drop old).

## Backward compatibility (one deploy cycle)

- Adding a NOT NULL column? Three migrations:
  1. Add nullable column.
  2. Backfill data.
  3. Add NOT NULL constraint.
- Renaming? Add new column → backfill → switch reads → drop old. Never a single rename in a live system.

## Indexes

- New indexes go in their **own migration**, not bundled with schema changes. Easier to roll back independently. Index creation can take a long time on large tables.

## Other rules

- Never seed production data in migration files. Use dedicated seed scripts.
- Never drop a column or table without first confirming the data is no longer read or written by any deployed code.
- Foreign keys: explicit `onDelete` behavior. `restrict` is the default; `cascade` only when intentional.
