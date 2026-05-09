# Claude Code Setup — Design Spec

**Date:** 2026-05-09
**Author:** Drew White (with brainstorming assist)
**Scope:** Global `~/.claude/` (symlinked from `~/Dev/drucial-dots/claude/`)

---

## 1. Goal

Build a global Claude Code config that delivers consistent, high-quality results across projects and sessions, enforces the user's mental model and coding standards, and allocates context tokens efficiently.

### Stated frustrations (in priority order)

1. **Consistency** — across projects, across sessions, even within a single session. The biggest pain.
2a. **Backend / data-layer patterns** — server actions, API routes, queries. Drifts session to session.
2b. **Extraction discipline** — Claude misses chances to break out shared components, utils, hooks. Especially bad at finding existing UI primitives before creating one-off pills/buttons/badges.

### Mental model (load-bearing)

- **`components/`** = UI layer (presentation only)
- **`utils/`** = Logic (pure functions, transforms, business rules)
- **`hooks/` + server actions** = Data layer (fetching, mutations, state)

---

## 2. Methodology

The design adapts the dotclaude methodology (`github.com/poshan0126/dotclaude`) — a tiered context-cost model with defense in depth.

### Four layers, ranked by cost

```
Layer 4: Skills + Agents      (workflow + isolated specialists)
Layer 3: Hooks                (deterministic guards)
Layer 2: Path-scoped rules    (load when files match)
Layer 1: CLAUDE.md + always   (every turn)
```

### Cost discipline

| Tier | Loads when | Cost |
|---|---|---|
| `CLAUDE.md` + `alwaysApply` rules | Session start | Every turn |
| Path-scoped rules (`paths:` glob) | A matching file is touched | Only when relevant |
| Hooks | Their event fires (PreToolUse / PostToolUse / SessionStart) | Just-in-time, not loaded as text |
| Skills (`/name`) | User invokes | Only on invocation |
| Agents (`@name` / auto-delegated) | Delegated to | Only on invocation, isolated context |

**Always-loaded budget:** target ~80 lines combined across `CLAUDE.md` + `alwaysApply` rules (see §12). Hard cap: 100 lines.

### Defense in depth

Each target behavior is reinforced at multiple layers so drift at one layer is caught by another. This is the central tool against frustration #1 (consistency).

| Behavior | L1 (always) | L2 (path-scoped) | L3 (hook) | L4 (skill/agent) |
|---|---|---|---|---|
| Tri-layer separation (UI/logic/data) | mental model rule | `frontend.md`, `backend.md`, `data-layer.md` | — | `/feature`, `@design-ux-architect` |
| Reuse before build | `reuse.md` with concrete primitives | `frontend.md` examples | `check-primitives.sh` (pre-edit) | `/component`, `@design-ui-designer` |
| Extraction discipline | `code-quality.md` | — | `nudge-duplication.sh` (post-edit) | `/extract` |
| Server action shape | — | `backend.md` | — | `/api`, `@backend-architect` |
| Marketing copy | — | `marketing.md` | — | `@marketing-content-creator` + `@marketing-seo-specialist` |
| Test discipline | `testing.md` | — | — | `/feature` checkpoint |

---

## 3. Architecture

### Final file structure

```
~/Dev/drucial-dots/claude/         (symlinked into ~/.claude/)
├── CLAUDE.md                      [MODIFIED — slim to ~30 lines]
├── settings.json                  [MODIFIED — wire hooks]
├── install                        [unchanged]
├── rules/                         [NEW]
│   ├── code-quality.md            (always, ~25 lines)
│   ├── reuse.md                   (always, ~15 lines)
│   ├── testing.md                 (always, ~10 lines)
│   ├── frontend.md                (paths: **/*.tsx, components/**, app/**)
│   ├── backend.md                 (paths: app/api/**, **/route.ts, **/actions.ts)
│   ├── data-layer.md              (paths: hooks/**, **/actions.ts, **/queries/**, lib/db/**)
│   ├── marketing.md               (paths: **/(marketing)/**, **/marketing/**, **/landing/**)
│   ├── security.md                (paths: **/api/**, **/auth/**, **/middleware/**, **/route.ts)
│   └── migrations.md              (paths: **/migrations/**, **/drizzle/**, **/prisma/migrations/**)
├── hooks/                         [NEW]
│   ├── protect-files.sh           (stolen from dotclaude)
│   ├── scan-secrets.sh            (stolen)
│   ├── block-dangerous-commands.sh (stolen)
│   ├── format-on-save.sh          (stolen — Prettier focus)
│   ├── session-start.sh           (stolen — minimal)
│   ├── check-primitives.sh        [NOVEL — pre-edit primitive grep]
│   └── nudge-duplication.sh       [NOVEL — post-edit duplication scan]
├── skills/
│   ├── ship/                      [MODIFIED — add Step 0 typecheck+lint verification]
│   ├── feature/SKILL.md           [NEW — multi-file workflow with mental-model checkpoints]
│   ├── component/SKILL.md         [NEW — forced grep, ui-designer → ux-architect chain]
│   ├── extract/SKILL.md           [NEW — review recent diff, propose extractions]
│   └── api/SKILL.md               [NEW — server action / route workflow]
└── agents/                        [REFACTORED — see §6]
```

---

## 4. Conventions (extracted from user's repos)

Captured from `auranote-v2`, `reecv`, `drucial-app`, `praxis-labs`. (`craftwork` referenced for data patterns only — not user's code.)

### File organization

- **Top-level:** `app/`, `components/`, `lib/`, `hooks/`, `utils/` (or `db/`)
- **UI primitives:** `components/ui/` shadcn-style
- **Feature components:** `components/{feature}/` or `components/views/`, `components/shared/`, `components/layout/`
- **Lib organized by function:** `lib/db/`, `lib/auth/`, `lib/trpc/`, `lib/ai/`, `lib/actions/` — never a flat dump
- **Hooks:** `hooks/{domain}/` with `use-*.ts`, fully typed return values
- **Server actions:** `lib/actions/` (auranote) or `actions/` at root (praxis); `"use server"` directive

### Naming

- **Component files:** kebab-case (`entry-type-button.tsx`)
- **Component exports:** PascalCase (`EntryTypeButton`)
- **Hooks:** `use-*.ts` (kebab-case file, camelCase export)
- **Lib files:** kebab-case (`auth-client.ts`, `validations.ts`)
- **Directories:** kebab-case

> ⚠️ Note: existing `~/.claude/CLAUDE.md` says "PascalCase for components" but actual user repos are kebab-case files / PascalCase exports. The new `code-quality.md` will codify the real convention.

### Data layer

- **ORM:** Drizzle (auranote, reecv) or Prisma (praxis); both common
- **Client-side queries:** **TanStack Query** for all DB ops in React apps (`useQuery`, `useMutation`, `useInfiniteQuery`, queryKey conventions, cache invalidation, optimistic updates). Pairs with server actions for mutations.
- **Validation:** Zod schemas in `lib/validations.ts`
- **Forms:** react-hook-form + zod resolver; never rolled-own form state
- **Global client state:** React Context only when prop drilling is genuinely painful. **No Zustand/Jotai/Redux.** Server state belongs in TanStack Query.

### Testing

- **Runner:** Vitest + React Testing Library (when tests exist; many repos have none)
- **Location:** co-located `__tests__/` next to source
- **Naming:** `*.test.ts` / `*.test.tsx`

---

## 5. Rule contents (overview)

### Always-loaded (target ~50 lines combined)

**`CLAUDE.md`** (~30 lines):
- Mental model (UI/logic/data)
- Anti-defaults (no premature abstraction, no scope creep, no surrounding refactors)
- Workflow checkpoints (Plan Before Implementing, Reuse Before Building, Root-Cause Before Patching, Pre-PR Checklist, Memory Loop)

**`code-quality.md`** (~25 lines):
- TS strictness (no `any`, no `as`, `import type`, remove unused)
- Naming: kebab-case files, PascalCase component exports, `use-*.ts` for hooks, `is/has/should` boolean prefix
- Comment policy: WHY-not-WHAT, no commented-out blocks
- Code markers: `TODO(@author)`, `FIXME(@author)` with issue link

**`reuse.md`** (~15 lines):
- Grep `components/ui/` before creating any UI element
- Concrete primitive list: button, pill, badge, chip, card, input, modal, tooltip, popover, dropdown, dialog, toast, avatar, skeleton
- Never modify shared components without explicit ask

**`testing.md`** (~10 lines):
- Vitest + React Testing Library
- Co-located `__tests__/`, `*.test.ts(x)`
- One assertion per test; verify behavior not implementation; fix or delete flaky tests

### Path-scoped

**`frontend.md`**:
- Tri-layer reminder: components are UI only; pull logic to utils, data to hooks/server actions
- Tailwind: tailwind-merge precedence, parent-tree tracing for layout bugs, no `!important` without investigating cascade
- Forms: react-hook-form + zod resolver, schemas in `lib/validations.ts`
- State: React Context only when prop drilling is painful; no global state libs; server state via TanStack Query
- Accessibility: WCAG AA — keyboard, alt, contrast, focus indicators
- Performance: `loading="lazy"`, `font-display: swap`, transform/opacity-only animations, virtualize 100+ lists
- **Auto-delegate:** for all frontend work, invoke `@design-ux-architect`. For net-new UI, invoke `@design-ui-designer` then `@design-ux-architect` in sequence.

**`backend.md`**:
- Server action shape: `"use server"`, Zod validation at top, typed return, try/catch with typed errors
- API route conventions, error response shape consistency
- Never embed UI logic in server code
- Use Drizzle/Prisma schema types as source of truth

**`data-layer.md`**:
- Server actions: `lib/actions/{domain}.ts`, named verb-first (`getEntry`, `createEntry`, `updateEntry`)
- TanStack Query: queryKey conventions (`['entries', filters]`), `useMutation` with optimistic updates and `invalidateQueries` on success
- For Next.js: server components fetch directly, client components use TanStack Query (often calling server actions)
- Custom hooks in `hooks/{domain}/` wrap TanStack Query for reusable data fetching

**`marketing.md`**:
- For ALL marketing copy / page work, delegate to `@marketing-content-creator` AND `@marketing-seo-specialist` in parallel

**`security.md`**:
- Input validation with Zod at API boundaries
- Parameterized queries only (Drizzle/Prisma make this default; avoid raw SQL escape hatches)
- Sessions: httpOnly cookies, no tokens in localStorage
- Never log secrets, request bodies, or auth headers
- Rate limiting on public endpoints
- Security headers (CSP, HSTS, X-Frame-Options) via middleware

**`migrations.md`**:
- Never modify an existing migration — create a new one
- Reversibility required: implement up AND down
- NOT NULL columns require backfill in a separate prior migration
- No seed data in migrations — use dedicated seed files
- Indexes go in their own migration

---

## 6. Agent strategy

### Final inventory (7 kept globally + 2 moved to project)

| Agent | Action | Mechanism |
|---|---|---|
| `design-ux-architect` | Keep, **auto-invoke for ALL frontend** | description + `frontend.md` reference |
| `design-ui-designer` | Keep, **auto-invoke for net-new UI, always chained to ux-architect** | `/component` skill enforces sequence; description says "always pair with ux-architect after" |
| `backend-architect` | Keep, **revamp** | refocus on Next.js server actions, Drizzle/Prisma schema decisions, Zod validation |
| `database-optimizer` | Keep, **revamp** | refocus on Drizzle/Prisma query tuning, N+1 detection in server actions |
| `marketing-content-creator` | Keep, **auto-invoke on marketing pages** | `marketing.md` rule + description |
| `marketing-seo-specialist` | Keep, **auto-invoke on marketing pages** | `marketing.md` rule + description |
| `marketing-growth-hacker` | Keep as-is | manual invocation |
| `design-brand-guardian` | **Delete** | — |
| `design-visual-storyteller` | **Delete** | — |
| `design-whimsy-injector` | **Delete** | — |
| `recruitment-specialist` | **Move to `~/Dev/reecv/.claude/agents/`** | project-local |
| `specialized-document-generator` | **Move to `~/Dev/reecv/.claude/agents/`** | project-local |

### Refactor pattern for kept agents

Currently persona-heavy (vibe lines, emojis, "Identity & Memory"). Refactor each to:

- Tight description that triggers auto-delegation reliably
- Concrete output format (file:line, severity, fix — like dotclaude's `code-reviewer.md`)
- ≥80% confidence threshold; drop nitpicks
- Default to terse output

Target: ~50% of current length per agent.

---

## 7. Lifecycle (composition in real sessions)

### Session start

```
SessionStart hook fires      → injects branch + dirty state    (~5 tokens)
CLAUDE.md loads              → mental model + anti-defaults    (~30 lines)
alwaysApply rules load       → code-quality + reuse + testing  (~50 lines combined)
Path-scoped rules            → dormant
Hooks                        → registered, dormant
Skills/agents                → metadata indexed
```

### Walkthrough A: *"Add a tag pill to the entry view"*

```
1. Claude opens components/views/entry/entry-card.tsx
   → frontend.md auto-loads (path matches **/*.tsx)
   → frontend.md says: "components are UI only. Reuse primitives.
                        For frontend work, delegate to @design-ux-architect"

2. Claude is about to Write components/ui/tag-pill.tsx
   → PreToolUse: check-primitives.sh fires
     • greps components/ui/ for /pill|badge|chip|tag/i
     • finds components/ui/badge.tsx
     • returns: "⚠ Existing primitive: components/ui/badge.tsx — consider reusing"
   → Claude reads badge.tsx, uses <Badge variant="tag"> instead

3. Edit applied
   → PreToolUse: protect-files ✓, scan-secrets ✓
   → PostToolUse: format-on-save runs Prettier
   → PostToolUse: nudge-duplication.sh scans diff
     • finds Badge composition repeated 3x
     • nudges: "Pattern repeated 3x — extraction candidate"

4. /extract (manual or follow-up)
   → proposes <TagBadgeList tags={tags}/> extraction
```

### Walkthrough B: *"Write the hero for the landing page"*

```
1. Claude opens app/(marketing)/page.tsx
   → frontend.md loads (matches **/*.tsx)
   → marketing.md loads (matches **/(marketing)/**)
     → "delegate to @marketing-content-creator AND @marketing-seo-specialist"

2. Parallel delegation:
   → @marketing-content-creator drafts copy in isolated context
   → @marketing-seo-specialist proposes meta tags, headings, structured data
   → Both return; main session synthesizes

3. Implementation uses existing primitives (check-primitives.sh fires on any new UI file)
4. Hooks: format-on-save → done
```

### Walkthrough C: *"Add a server action to update entry tags"*

```
1. Claude opens lib/actions/entries.ts
   → backend.md loads (matches **/actions.ts)
   → data-layer.md loads (matches **/actions.ts)
   → security.md does NOT load (path doesn't match api/auth)

2. Claude writes action following pattern:
   - "use server"
   - Zod validate input
   - Typed return shape
   - revalidatePath/revalidateTag on success

3. Claude pairs with TanStack Query hook in hooks/entries/
   → useMutation wrapping the action
   → invalidateQueries on success

4. Tests in __tests__/ co-located (testing.md)
5. /ship → typecheck + lint → commit → push → PR
```

---

## 8. Rollout phases

Each phase is shippable on its own.

### Phase 1 — Foundation
- Trim `CLAUDE.md` to ~30 lines
- Create `rules/` with `code-quality.md`, `reuse.md`, `testing.md`
- Create `hooks/` with 5 stolen safety hooks
- Wire hooks in `settings.json`
- Verify always-loaded total stays under 100-line hard cap (target ~80) via context audit
- **Add Memory Loop discipline** to `CLAUDE.md` workflow

### Phase 2 — Path-scoped rules
- `frontend.md` (with TanStack Query, react-hook-form, Context-only state notes, ux-architect delegation)
- `backend.md` (server action shape, Zod, error handling)
- `data-layer.md` (Drizzle/Prisma + TanStack Query patterns)
- `marketing.md` (auto-delegate to content + SEO)
- `security.md` (auth/api safety)
- `migrations.md` (DB migration discipline)

### Phase 3 — Skills
- `/feature`, `/component`, `/extract`, `/api`
- Modify `/ship`: add Step 0 typecheck + lint on changed files

### Phase 4 — Agent overhaul
- Delete: `design-brand-guardian`, `design-visual-storyteller`, `design-whimsy-injector`
- Move: `recruitment-specialist`, `specialized-document-generator` → `~/Dev/reecv/.claude/agents/`
- Refactor 7 kept agents (drop persona, tighten descriptions, add output formats)
- Revamp `backend-architect` and `database-optimizer` for actual stack

### Phase 5 — Novel hooks
- `hooks/check-primitives.sh` — pre-edit primitive grep
- `hooks/nudge-duplication.sh` — post-edit duplication scan
- Tune false-positive rate over a week of real use

---

## 9. Open work to capture during implementation

| Where | What we'll capture | When |
|---|---|---|
| `backend.md` | User's specific server action conventions: Zod placement, error return shape, revalidate pattern | Phase 2 — show drafts based on auranote/praxis; user confirms |
| `data-layer.md` | Drizzle vs Prisma per-project preference; TanStack Query queryKey conventions; mutation flow | Phase 2 — show drafts; user confirms |
| `testing.md` | Final convention list (most repos have no tests; auranote uses Vitest) | Phase 1 — quick conversation |
| Agent descriptions | Final wording for reliable auto-delegation | Phase 4 — review drafts |
| `backend-architect` revamp | What user wants this agent to actually do | Phase 4 — short spec |
| `database-optimizer` revamp | Same | Phase 4 — short spec |

---

## 10. Risks & mitigations

| Risk | Mitigation |
|---|---|
| `check-primitives.sh` false positives | Returns a *nudge* (system message), not a *block* (exit 2). Claude can override when justified. |
| `nudge-duplication.sh` too noisy | Threshold: only fires at 2+ matches. Tune in Phase 5. |
| Path-scoped rules don't load on work projects with deviating paths | Globs are loose (`**/*.tsx`, not `src/components/**/*.tsx`). Guidance is intent-based, not location-based. |
| Auto-delegation to agents doesn't fire reliably | Belt-and-suspenders: agent description + rule reference + skill (e.g., `/component` explicitly invokes the chain). |
| Always-loaded budget creep over time | `/context-budget`-style audit at end of each phase. Hard cap: 100 lines combined. |
| Pre-ship typecheck blocks legitimate WIP commits | `/ship` has explicit "skip" option per step (matches existing skill pattern). |
| Agents in reecv don't load automatically | Project-local `.claude/agents/` is read by Claude Code in that project root. Verify after move. |

---

## 11. Verification per phase

| Phase | How we verify |
|---|---|
| 1 | Fresh session loads CLAUDE.md + rules; trigger each safety hook (try editing `.env` → blocked, try `git push --force` → blocked, write to `dist/foo.js` → blocked, secret in file content → blocked, edit `.tsx` → format-on-save runs) |
| 2 | Open files in different layers, confirm only the relevant rule loads |
| 3 | Run each skill end-to-end on a real task; `/ship` blocks when typecheck fails |
| 4 | Pruned agents gone; moved agents work in reecv; kept agents trigger on relevant requests |
| 5 | Edit `.tsx` with a primitive name → check-primitives.sh nudges. Make duplicated edits → nudge-duplication.sh fires. |

---

## 12. Token budget

| Tier | Lines | Loads |
|---|---|---|
| `CLAUDE.md` | ~30 | every turn |
| `code-quality.md` | ~25 | every turn |
| `reuse.md` | ~15 | every turn |
| `testing.md` | ~10 | every turn |
| **Always-loaded total** | **~80 lines** | **every turn** |
| `frontend.md` | ~50 | when `**/*.tsx` etc. |
| `backend.md` | ~30 | when API/action files |
| `data-layer.md` | ~40 | when hooks/actions/queries |
| `marketing.md` | ~10 | when marketing paths |
| `security.md` | ~30 | when api/auth/middleware |
| `migrations.md` | ~15 | when migration dirs |
| Skills | ~30-80 each | only when invoked |
| Agents | ~50-100 each | only when delegated |

Hard cap on always-loaded: **100 lines.** If exceeded, demote rules to path-scoped.

---

## 13. Success criteria

This setup is working if, after Phase 5 has run for ~2 weeks of real use:

1. Claude consistently uses existing UI primitives (`components/ui/`) instead of creating one-offs.
2. Claude consistently follows the tri-layer model (UI / logic / data) without prompting.
3. Server action shape is identical across new code in different sessions.
4. `@design-ux-architect` is invoked for all frontend work without manual `@` mentions.
5. Marketing pages auto-trigger the content + SEO agent pair.
6. `/ship` typecheck-and-lint gate has caught at least one regression that would have shipped.
7. Always-loaded budget stays under 100 lines.
8. Memory file accumulates user corrections; same correction never needed twice across sessions.
