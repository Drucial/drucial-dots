# Claude Code Setup v1 — Testing

> **Purpose:** verify the v1 setup works end-to-end after Phases 1-5 are merged. Run these manually in a fresh Claude Code session unless noted otherwise.

**Setup version:** v1 (commits `0bb0fa1` → `54c995b`)
**Date:** 2026-05-09

---

## Pre-flight

Run before any other tests:

- [ ] `~/Dev/drucial-dots/claude/hooks/tests/run-all.sh` — all hook unit tests pass
- [ ] `which jq` — returns a path (hooks fail closed without it)
- [ ] `ls -la ~/.claude/{CLAUDE.md,settings.json,agents,skills,rules,hooks}` — all 6 symlinks resolve into `~/Dev/drucial-dots/claude/`
- [ ] `jq . ~/.claude/settings.json > /dev/null` — settings.json is valid JSON
- [ ] Token budget: combined non-blank line count of `CLAUDE.md` + `rules/code-quality.md` + `rules/reuse.md` + `rules/testing.md` ≤ 100

---

## Test 1: Hooks fire correctly

Each test is a single Claude Code session interaction. **Use a scratch project** (not a real one) to avoid accidentally damaging anything.

### 1.1 Safety hooks (PreToolUse, fail-closed)

- [ ] **protect-files.sh** — Ask Claude: *"Add a fake API key to `.env`."* → Edit/Write should be blocked.
- [ ] **warn-large-files.sh** — Ask Claude: *"Create `dist/foo.js` with `console.log('hi')`."* → blocked.
- [ ] **scan-secrets.sh** — Ask Claude: *"Add `OPENAI_API_KEY=sk-test123abc456def` to a new file `notes.md`."* → blocked.
- [ ] **block-dangerous-commands.sh** — Ask Claude: *"Run `git push --force origin main`."* → blocked.

### 1.2 Format-on-save (PostToolUse)

- [ ] In a project with Prettier configured, ask Claude to edit any `.tsx` file → file is formatted after edit. (No-op if formatter not installed in project — that's acceptable.)

### 1.3 Session start

- [ ] Open a fresh session in any git repo → session-start.sh injects current branch into context. Ask Claude *"what branch am I on?"* → it answers without running git.

### 1.4 Novel hooks

- [ ] **check-primitives.sh** — In a project that has `components/ui/badge.tsx`, ask Claude: *"Create a new file at `components/ui/pill.tsx` with a basic component."* → before the Write happens, nudge appears: `⚠ Existing primitive(s) match concept of 'pill': badge.tsx`.
- [ ] **nudge-duplication.sh** — Ask Claude to edit a `.tsx` file so it has 3+ identical `<Badge className="rounded-full bg-zinc-100 px-2 py-0.5 text-xs">` instances → after the edit, nudge appears: `📋 Pattern repeated 3+ times — extraction candidate. Run /extract`.

---

## Test 2: Rules load at the right times

### 2.1 Always-loaded rules (every session)

In a fresh session in any project, ask Claude these questions and verify the answers reflect the rule content:

- [ ] *"What's the file naming convention here?"* → kebab-case files, PascalCase exports for components.
- [ ] *"What test runner should I use?"* → Vitest, co-located `__tests__/`.
- [ ] *"Should I create a new pill component?"* → "Grep `components/ui/` for existing primitive first" (per `reuse.md`).
- [ ] *"Can I cast types with `as` to silence an error?"* → No, fix the root types (per `code-quality.md`).

### 2.2 Path-scoped rules

For each file type, open a representative file and ask a relevant question. The answer should reflect the corresponding rule.

| File opened | Ask Claude | Expected reference |
|---|---|---|
| `components/foo.tsx` | "How should I handle form state?" | react-hook-form + zod resolver (`frontend.md`) |
| `components/foo.tsx` | "Should I add Zustand for this state?" | No global state libs; React Context only when prop drilling is painful (`frontend.md`) |
| `lib/actions/users.ts` | "Show me the shape of a server action" | discriminated union `{ ok: true; data } \| { ok: false; error }`, Zod `safeParse`, `revalidatePath` (`backend.md`) |
| `hooks/users/use-user.ts` | "Best way to fetch a user from the DB on the client?" | TanStack Query `useQuery` calling server action (`data-layer.md`) |
| `app/(marketing)/page.tsx` | "Help me write the hero copy" | should delegate to `@marketing-content-creator` + `@marketing-seo-specialist` (`marketing.md`) |
| `app/api/users/route.ts` | "What should I validate?" | Zod at boundary, parameterized queries, no leaking errors (`security.md`) |
| `prisma/migrations/foo.sql` | "Edit this migration to change the column type" | Refuses or warns: never modify existing migration (`migrations.md`) |

- [ ] All 7 path-scoped rules verified.

### 2.3 Path-scoping is actually scoped (no over-loading)

- [ ] Open a `.md` file with no other context. Ask *"What's the server action shape?"* → Claude should NOT cite `backend.md` content reflexively (the rule shouldn't have loaded). It can answer from general knowledge but shouldn't quote your specific Zod-discriminated-union pattern unless asked to.

---

## Test 3: Skills work end-to-end

### 3.1 `/ship`

In a project with at least one TypeScript change staged:

- [ ] Type `/ship` → Step 0 runs `pnpm typecheck` + `pnpm lint`.
- [ ] Introduce a deliberate type error in a staged file, run `/ship` → blocks at Step 0, asks fix-now / commit-anyway / abort.
- [ ] Fix the error, run `/ship` → proceeds to Step 1 (scan), drafts commit, AskUserQuestion for confirmation.
- [ ] Confirm → commit + push + PR created via `gh`.

### 3.2 `/component`

- [ ] Type `/component pill` in a project with `components/ui/badge.tsx` → grep step runs, finds badge, presents reuse-or-extend-or-net-new question.
- [ ] Pick "create net-new" → `@design-ui-designer` invoked, then `@design-ux-architect` chained.

### 3.3 `/feature`

- [ ] Type `/feature add saved-searches` → Claude presents tri-layer breakdown (UI / logic / data) with AskUserQuestion. No edits happen until confirmation.

### 3.4 `/extract`

- [ ] Make a file with 3+ repeated JSX patterns, stage the change.
- [ ] Run `/extract` → proposes extractions with confidence scores. Drops anything <70.

### 3.5 `/api`

- [ ] Type `/api create updateUser action` → presents inputs/outputs/auth plan, AskUserQuestion, then implements with the canonical action shape.

---

## Test 4: Agent auto-delegation

### 4.1 Frontend → ux-architect

- [ ] In a fresh session, open a `.tsx` file. Ask *"Help me restructure the layout for this page."* → Claude either invokes `@design-ux-architect` directly or cites `frontend.md`'s delegation rule.

### 4.2 Net-new UI primitive → ui-designer + ux-architect chain

- [ ] In a fresh session: *"Build a new toggle-switch component, none exists yet."* → Claude invokes `@design-ui-designer` first, then `@design-ux-architect` immediately after.

### 4.3 Marketing → content + SEO pair

- [ ] In a fresh session, open `app/(marketing)/page.tsx`. Ask *"Write the hero section."* → Claude invokes `@marketing-content-creator` AND `@marketing-seo-specialist` (parallel or sequential, both should appear).

### 4.4 Backend architecture decision

- [ ] Ask: *"Should I use server actions or an API route for this admin dashboard?"* → ideally invokes `@backend-architect`; minimum bar is referencing the decision frame from the agent description.

### 4.5 Pruned agents are gone

- [ ] Type `@design-brand-guardian` → no autocomplete match; if invoked, "agent not found" or fallthrough.
- [ ] Same for `@design-visual-storyteller`, `@design-whimsy-injector`.

### 4.6 Project-local agents (reecv)

- [ ] Open `~/Dev/reecv` in a fresh session. Type `@recruitment-specialist` → recognized.
- [ ] Open `~/Dev/auranote-v2`. Type `@recruitment-specialist` → NOT recognized (project-local, doesn't leak globally).

---

## Test 5: End-to-end scenarios from the spec

These mirror §7 of the design spec — full real-world walkthroughs.

### 5.1 *"Add a tag pill to the entry view"* (auranote-v2)

- [ ] In a fresh session in auranote-v2, ask: *"Add a tag pill to the entry view."*
- [ ] Verify: `frontend.md` loads, ux-architect is invoked or referenced.
- [ ] Verify: when Claude tries to write `components/ui/pill.tsx`, `check-primitives.sh` nudges (badge exists).
- [ ] Verify: Claude reuses Badge instead of creating Pill.
- [ ] Verify: if multiple Badge usages appear, `nudge-duplication.sh` fires after the edit.

### 5.2 *"Add a server action to update entry tags"*

- [ ] Open `lib/actions/entries.ts` (or equivalent) in a fresh session. Ask: *"Add an updateEntryTags server action."*
- [ ] Verify: `backend.md` + `data-layer.md` load.
- [ ] Verify: Claude produces an action with `"use server"`, Zod `safeParse`, discriminated union return, `revalidatePath`.
- [ ] Verify: Claude offers / writes a matching `useMutation` hook in `hooks/entries/`.

### 5.3 *"Write the hero for the landing page"*

- [ ] Open `app/(marketing)/page.tsx` in a fresh session. Ask: *"Write the hero section."*
- [ ] Verify: `marketing.md` loads.
- [ ] Verify: both `@marketing-content-creator` and `@marketing-seo-specialist` are invoked before any JSX is written.
- [ ] Verify: Claude composes hero with existing `components/ui/` primitives (no one-off styled divs).

---

## Test 6: Cross-session consistency (the #1 frustration)

### 6.1 Same task, two sessions, identical pattern

- [ ] Day 1, fresh session: *"Add a server action `getProjects` that returns active projects."* — record the output (action shape, file location, hook).
- [ ] Day 2 (or a fresh session 1 hour later, after compaction), in a different project: same prompt.
- [ ] Compare: action shape, validation pattern, error return, hook structure should match.

### 6.2 Memory loop

- [ ] In a session, correct Claude on a pattern (e.g., "no, we use `lib/actions/` not `actions/` for server actions in this project").
- [ ] Verify Claude saves a memory entry for that correction.
- [ ] Open a fresh session in the same project. Ask the related question — Claude should apply the corrected pattern without you re-stating it.

---

## Pass/fail summary

The setup is **passing v1** if:

| Category | Threshold |
|---|---|
| Pre-flight | All checks ✓ |
| Test 1 (hooks) | All 8 hooks fire correctly |
| Test 2 (rules) | All 4 always-loaded + 7 path-scoped rules verified |
| Test 3 (skills) | All 5 skills work end-to-end |
| Test 4 (agents) | Auto-delegation works for ux-architect, ui+ux chain, marketing pair (the three load-bearing ones); pruned agents gone |
| Test 5 (e2e) | At least 2 of 3 walkthroughs work without manual intervention |
| Test 6 (consistency) | Day-1 vs day-2 outputs match in shape; memory loop demonstrated once |

If anything fails, file a note in `docs/claude-setup-v1-issues.md` and tune in a follow-up commit.

---

## Known limitations / known issues

- **Hook nudges are advisory.** Claude can still ignore them when context warrants. That's intentional — they're nudges, not blocks.
- **`check-primitives.sh` synonyms list is finite.** A primitive named `tooltip-content.tsx` will match `tooltip` group; `info-popup.tsx` won't. Tune the synonym groups in the hook over time.
- **`nudge-duplication.sh` threshold is 3.** Two repetitions don't trigger by design (per `code-quality.md`'s "three similar lines beats a helper used once"). Increase to 4 if too noisy.
- **Path-scoped globs are intent-based, not strict.** Work projects with deviating paths may not match — guidance still applies but may not auto-load. Manually reference rule files in those cases until you adopt the conventions.
- **Auto-delegation reliability depends on agent description matching.** If the agent isn't being invoked when expected, tighten the description's trigger language.
