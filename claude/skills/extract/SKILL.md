---
name: extract
description: Review recent diff (or specified files) and propose extractions for repeated patterns into shared components, utils, or hooks.
argument-hint: "[file path or 'staged' or 'last-commit' — defaults to staged]"
disable-model-invocation: true
allowed-tools:
  - Bash(git diff *)
  - Bash(git log *)
  - Bash(git show *)
  - Bash(rg *)
  - Read
  - Glob
---

Review recent code changes and propose extractions. $ARGUMENTS specifies what to review (defaults to staged changes).

## Step 1: Gather the diff

- If $ARGUMENTS is empty or "staged": `git diff --cached`
- If "last-commit": `git show HEAD`
- If a file path: `git diff -- <path>` (or read the file directly if uncommitted)

## Step 2: Scan for extraction signals

Look for:

### Component extraction signals
- Same JSX block (3+ similar lines) repeated 2+ times in the diff.
- Repeated Tailwind class strings (4+ classes) used in 2+ places.
- Inline styled wrappers (`<div className="rounded-full bg-... px-... py-...">{x}</div>`) that match common primitive shapes.

### Util extraction signals
- Same logic block (3+ lines) repeated 2+ times.
- Inline transforms (date formatting, string manipulation, calculations) used in 2+ places.
- Conditionals or filters that have semantic meaning ("isOverdue", "formatDuration", "groupByDate").

### Hook extraction signals
- Repeated `useEffect`/`useState` patterns with similar logic in 2+ components.
- Inline TanStack Query calls in 2+ places (should be a hook in `hooks/{domain}/`).
- Repeated event listener setup/teardown.

## Step 3: Propose extractions

For each candidate, present:

- **Pattern**: what's repeated (file:line citations).
- **Extraction**: where it would live (`components/ui/...`, `lib/utils/...`, `hooks/{domain}/...`).
- **Diff sketch**: the new file's content + how callers change.
- **Confidence** (0-100): how sure are we this is a real extraction vs coincidental similarity?

Default to **only ≥70 confidence**. Note lower-confidence candidates briefly but don't push them.

## Step 4: Confirm with user

Use `AskUserQuestion`. Let user pick which extractions to apply.

## Step 5: Apply selected extractions

For each accepted:
- Create the new file.
- Update callers (one Edit per caller).
- Run `pnpm typecheck` after each.

## Step 6: Verify

- `pnpm typecheck`, `pnpm lint`, run affected tests.
- Don't commit — let the user run `/ship`.

## Rules

- Don't propose extractions in code outside the diff scope.
- Don't suggest premature abstractions: 2 occurrences = candidate, 3+ = strong candidate. 1 = leave it alone (per `rules/code-quality.md`).
- Component extractions must check `rules/reuse.md` first — if a primitive already exists, use it instead of creating a new one.
