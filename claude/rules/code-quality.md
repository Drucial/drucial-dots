---
alwaysApply: true
---

# Code Quality

## Anti-defaults (counter common Claude tendencies)

- No premature abstractions. Three similar lines beats a helper used once.
- Don't add features or improvements beyond what was asked.
- Don't refactor adjacent code while fixing a bug.
- No dead code or commented-out blocks.
- WHY comments only, never WHAT. If code needs a "what" comment, rename instead.

## TypeScript

- Never use `any` — use proper types, `unknown`, or generics.
- Avoid type casting (`as`) — fix the root types instead.
- Use `import type` for type-only imports.
- Prefer `type` over `interface`.
- Remove unused imports/vars entirely — no underscore prefixes.

## Naming

- **Files**: kebab-case (`entry-card.tsx`, `auth-client.ts`, `use-entry-phase.ts`).
- **Component exports**: PascalCase (`EntryCard`).
- **Hooks**: `use-*.ts` files; camelCase exports (`useEntryPhase`).
- **Booleans**: `is` / `has` / `should` / `can` prefix.
- **Functions**: verb-first (`getUser`, `createEntry`).
- **Constants**: `SCREAMING_SNAKE`.

## Code markers

- `TODO(@drew): desc` for planned work.
- `FIXME(@drew): desc (#issue)` for known bugs.
- `HACK(@drew): desc` for ugly workarounds (explain proper fix).
- Never `XXX`, `TEMP`, `REMOVEME`.
