---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/components/**"
  - "**/app/**/page.tsx"
  - "**/app/**/layout.tsx"
  - "**/styles/**"
  - "**/*.css"
---

# Frontend

## Tri-layer reminder

Components are UI only. Pull logic into `utils/` or `lib/`. Pull data into `hooks/{domain}/` or server actions. A component that fetches data or transforms is doing too much.

## Tailwind

- When a class doesn't apply, check tailwind-merge precedence and parent container constraints before stacking more classes or reaching for `!important`.
- Trace layout bugs through the full component tree (parent flex/grid/overflow/height rules) before tweaking the target element.
- Prefer semantic tokens over raw values. If `bg-background` exists, don't write `bg-zinc-50`.

## Forms

- **react-hook-form + zod resolver** for all forms. Never roll your own form state.
- Validation schemas in `lib/validations.ts`. Reuse across server action and form.
- Server-side: re-validate with the same schema in the action — never trust the client.

## Client state

- **No global state libraries** (no Zustand, Jotai, Redux). React Context only when prop drilling is genuinely painful (3+ levels).
- Server state belongs in TanStack Query, not Context.

## Data fetching from components

- Server components: fetch directly (no `'use client'`).
- Client components: use TanStack Query (`useQuery`, `useMutation`). For mutations that change DB state, call a server action from inside `useMutation` and `invalidateQueries` on success.

## Accessibility (non-negotiable)

- All interactive elements keyboard-accessible.
- Images: meaningful `alt` or `alt=""` for decorative.
- Form inputs: associated `<label>` or `aria-label`.
- Contrast: 4.5:1 normal text, 3:1 large.
- Visible focus indicators. Never `outline: none` without replacement.
- `prefers-reduced-motion` and `prefers-color-scheme` respected.

## Performance

- Images: `loading="lazy"` below fold, explicit `width`/`height`.
- Fonts: `font-display: swap`.
- Animations: `transform` and `opacity` only.
- Virtualize lists at 100+ items.

## Auto-delegation

- For ALL frontend work: delegate to `@design-ux-architect`.
- For NET-NEW UI primitives: delegate to `@design-ui-designer` first, then `@design-ux-architect` immediately after. Always paired in that order.
