---
paths:
  - "**/migrations/**"
  - "**/drizzle/**"
  - "**/prisma/migrations/**"
  - "**/db/migrate/**"
---

# Database migrations

## Never modify an existing migration

Once a migration has run anywhere (dev, staging, prod), it's frozen. Editing it creates drift between environments and corrupts the history. **Create a new migration** for changes.

## Destructive changes span multiple deploys

Renames, drops, type changes, and adding `NOT NULL` to a populated column can't safely happen in one migration if deployed code still reads the old shape. The pattern:

1. Migration A: add new column / table.
2. Application code: dual-write to old + new (or just write to new if reads still go to old).
3. Migration B: backfill old → new.
4. Application code: switch reads to new.
5. Migration C: drop the old column / table.

For `NOT NULL` specifically: add nullable → backfill → add the constraint. Three migrations across at least two deploys.

## Backfills

- Backfills can live in the **same migration** as the structural change that makes them necessary — that's fine and common. The exception is large multi-step destructive changes (above), where the backfill is its own migration so reads can switch in between.
- **Make backfills idempotent.** `WHERE NOT EXISTS`, `ON CONFLICT DO NOTHING`, `IF NOT EXISTS`. A migration that succeeds halfway then fails should be safely replayable.
- Print progress for non-trivial work. In Postgres: `RAISE NOTICE 'backfilled % rows', count`. The migration log is your only feedback once it's running.

## Indexes

- **Bundle indexes with their table on initial create.** New table + its indexes in one migration is one logical change.
- **New indexes on an existing large table go in their own migration.** Easier to roll back, easier to reason about timing, easier to run manually with `CONCURRENTLY` if needed.
- **No `CREATE INDEX CONCURRENTLY` inside a transaction-wrapped migration tool.** Drizzle, Prisma, and most ORMs wrap each migration in a transaction; `CONCURRENTLY` is incompatible. If you need one on a huge production table, run the index creation manually outside the migration apply path, then add a no-op `IF NOT EXISTS` index in a migration to track it in history.

## Soft-delete-aware uniqueness

If the codebase uses soft delete (`discarded_at`, `deleted_at`), any unique constraint that should permit re-creation after deletion must be a partial index:

```sql
CREATE UNIQUE INDEX "table_slug_unique" ON "table" ("slug") WHERE "discarded_at" IS NULL;
```

Never a bare `UNIQUE(...)` — discarded rows would block re-creation.

## Foreign keys

- Add explicitly with `ALTER TABLE ... ADD CONSTRAINT` rather than inline column definitions when the migration needs ordering control.
- Specify `ON DELETE` behavior. The right default is usually `RESTRICT` (let the FK error surface the cascade you didn't think through). Use `CASCADE` only when intentional and reviewed.

## Polymorphic associations

When a table can be owned by multiple parent types:

- Columns: `owner_type varchar(64) NOT NULL`, `owner_id integer NOT NULL` (or the corresponding ORM type).
- Index: composite on `(owner_type, owner_id)`.
- `owner_type` stores the **table name** (`'leads'`, `'employees'`), not a class name — table names are stable across language refactors.

## What not to do

- **Never seed production data in migration files.** Use dedicated seed scripts. Migrations are structural; seeds are content.
- **Never drop a column or table** without first confirming it's no longer read or written by any deployed code. The multi-step destructive pattern above covers this.
- **Never re-order or re-time historical migrations.** Even if it would "tidy up" the history, downstream environments won't replay.
