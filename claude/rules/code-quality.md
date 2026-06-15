# Code Quality

Stack-agnostic. The TypeScript section is opt-in — apply only when the project uses TS.

## Anti-defaults (counter common Claude tendencies)

- No premature abstractions. Three similar lines beats a helper used once.
- Don't add features or improvements beyond what was asked.
- Don't refactor adjacent code while fixing a bug.
- No dead code or commented-out blocks.
- WHY comments only, never WHAT. If code needs a "what" comment, rename instead.

## Naming

- **Files**: kebab-case (`entry-card.tsx`, `auth-client.ts`, `use-entry-phase.ts`). Follow the project's convention if it differs (`snake_case.rb`, `PascalCase.cs`).
- **Component exports** (any UI framework): PascalCase (`EntryCard`).
- **Hooks** (React): `use-*.ts` files; camelCase exports (`useEntryPhase`).
- **Booleans**: `is` / `has` / `should` / `can` prefix.
- **Functions**: verb-first (`getUser`, `createEntry`).
- **Constants**: `SCREAMING_SNAKE`.

## No defer markers

- Never leave `TODO`, `FIXME`, `HACK`, `XXX`, `TEMP`, or `REMOVEME` in code. A marker is a sign the thing should be fixed — so fix it now.
- Never use `eslint-disable` (or any equivalent suppression) to silence a violation. The violation is the signal to fix the code, not to annotate around it.
- Don't split "make the change" from "fix what it surfaced" — resolve surfaced issues in the same change.
- Genuinely out-of-scope future work belongs in a tracker (e.g. a Linear ticket), never as a comment in the code.

## TypeScript (apply only in TS projects)

- Never use `any` — use proper types, `unknown`, or generics.
- Avoid type casting (`as`) — fix the root types instead.
- Use `import type` for type-only imports.
- Prefer `type` over `interface`.
- Remove unused imports/vars entirely — no underscore prefixes.
