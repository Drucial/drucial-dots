---
name: feature
description: Multi-file feature workflow. Front-half plans (validity → outcome → UX → file plan); back-half builds tri-layer (UI/logic/data). Use for anything touching components + logic + data.
argument-hint: "[feature description]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(git log *)
  - Bash(git status)
  - Bash(git diff *)
  - Bash(ls *)
  - Bash(mkdir *)
  - Bash(pnpm typecheck *)
  - Bash(pnpm lint *)
  - Bash(pnpm test *)
  - Write
  - Edit
  - AskUserQuestion
---

Build a feature with explicit planning before code. $ARGUMENTS describes the feature.

The skill runs in two halves:

- **Front half (Phases 1–5)**: planning, validity, UX, file plan. Output: a plan ready to build.
- **Back half (Phases 6–9)**: build, test, verify, hand off.

For trivial changes, scale each phase down — a one-line outcome and a UI sketch may be enough. For non-trivial features, take each phase seriously.

If the user has already produced a design doc via `/office-hours` (look in `docs/specs/`), read it first and use it as the starting point for Phases 1–4. Skip phases that are already answered.

---

## Phase 1: Feature description

Capture the feature in the user's own words. If $ARGUMENTS is thin, ask once via `AskUserQuestion`:

- What does this feature do?
- Who uses it?
- What's the trigger (user action, scheduled, automatic)?

Output a one-paragraph restatement. Confirm with the user before continuing.

## Phase 2: Validity (premise check)

Before designing anything, push on the premise:

1. **Is this the right problem?** Could a different framing make the feature simpler or unnecessary?
2. **What happens if we do nothing?** Real pain or speculative?
3. **What existing code already partially solves this?** Grep `components/ui/`, `hooks/`, `lib/`, `utils/` per `rules/reuse.md`. Surface anything close.
4. **Is this the smallest version that's still valuable?** Or can it ship narrower?

If any of these reveal a better framing, restate the feature and loop back to Phase 1. Don't build the wrong thing well.

Output: 2–4 numbered premises the user must agree with. Confirm via `AskUserQuestion`.

## Phase 3: Desired outcome

Define what success looks like — observable, not hand-wavy.

Ask via `AskUserQuestion`:

- **Who benefits**, and how do they know it worked?
- **What observably changes** when this is shipped? (a metric, a flow that didn't exist, a step that's gone)
- **What's explicitly out of scope?** Name 1–2 non-goals.

Output:

```
OUTCOME
  Who:           <user / role>
  Observable:    <thing they can do that they couldn't before>
  Non-goals:     <thing we are NOT doing>
  Done when:     <one sentence>
```

If outcome reveals the validity check was off (different user, different problem), loop back to Phase 2.

## Phase 4: UX

Deep conversation about the experience. This is where most features get derailed by skipping ahead.

Walk through:

1. **Entry point**: how does the user arrive at this feature? (button, route, automatic)
2. **Happy path**: step-by-step, what does the user see and do?
3. **Empty / loading / error states**: what shows when there's nothing, while waiting, when it fails?
4. **Edge cases**: what happens if the user is unauthenticated, offline, mid-action, has no data, has too much data?
5. **Affordances and feedback**: how does the user know it worked? What's the recovery if they made a mistake?

Use `AskUserQuestion` for each unclear area, one question at a time. Sketch flows in plain text:

```
ENTRY: /tags page → "Suggest tags" button (top-right of toolbar)
  ↓
LOADING: button → spinner; toolbar disabled
  ↓
SUCCESS: bottom sheet appears with 5 suggestions, each with check/dismiss
  ↓ (user accepts some)
APPLY: selected tags merge into existing list; toast "3 tags added"
  ↓
ERROR: toast "Couldn't generate suggestions — try again", button re-enabled
```

For UI-heavy work, delegate to `@design-ux-architect` (per `rules/frontend.md`). For NET-NEW UI primitives, chain `@design-ui-designer` then `@design-ux-architect` (per `rules/reuse.md`).

Confirm the UX flow with the user before any code.

## Phase 5: Planning (mental-model checkpoint + file plan)

Now break the feature into the tri-layer model.

### 5a. Mental model

- **UI layer**: which components? new or extending existing? Grep `components/ui/` for primitives to reuse.
- **Logic layer**: pure functions / business rules / transforms. Where do they live (`utils/` or `lib/`)?
- **Data layer**: what data is read / mutated? Server action(s)? TanStack Query hook(s)?

Present this breakdown to the user with `AskUserQuestion`. Wait for confirmation or correction.

### 5b. File plan

List exact files to create or modify:

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

---

## Phase 6: Build outside-in (data → logic → UI)

1. Schema/types first (if DB shape changes).
2. Server action with Zod validation (per `rules/backend.md`).
3. TanStack Query hook wrapping the action (per `rules/data-layer.md`).
4. Pure logic helpers in `lib/{feature}/` if needed.
5. UI components, composing existing primitives (per `rules/reuse.md`).

After each layer, run `pnpm typecheck` to catch issues early.

## Phase 7: Tests

Co-located in `__tests__/` (per `rules/testing.md`). Test the logic layer first (pure functions are easiest). Test hooks with React Testing Library if hooks contain non-trivial logic.

## Phase 8: Verify

- `pnpm typecheck`
- `pnpm lint`
- Run the new tests

## Phase 9: Hand off

Summarize what was built and what remains. Suggest `/ship` if the feature is complete and tests pass.

---

## Rules

- Don't skip Phases 1–5. The whole point of this skill is forcing the planning. Scale each phase to the feature's size, but always do them.
- If a `docs/specs/` design doc exists for this feature, read it and use it as the starting point. Don't re-litigate decisions already made.
- Don't bundle unrelated improvements. Stay in-scope.
- For frontend portions, delegate to `@design-ux-architect` (per `rules/frontend.md`).
- For NET-NEW UI primitives, chain `@design-ui-designer` then `@design-ux-architect`.
