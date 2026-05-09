# Claude Code Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build out the global Claude Code config in `~/Dev/drucial-dots/claude/` per the design spec, in 5 shippable phases.

**Architecture:** Four-layer defense-in-depth — `CLAUDE.md` + `alwaysApply` rules → path-scoped rules → hooks → skills/agents. Each layer enforces the same target behaviors (consistency, tri-layer separation, reuse before build, extraction discipline) so drift at one layer is caught by another.

**Tech Stack:** Markdown with YAML frontmatter (rules, skills, agents); Bash + jq (hooks); JSON (settings); shadcn-style file naming (kebab-case files, PascalCase exports).

**Spec:** `docs/specs/2026-05-09-claude-setup-design.md`

**Source of truth:** `~/Dev/drucial-dots/claude/` (symlinked into `~/.claude/`)

**Reference repo for hooks:** `~/Dev/dotclaude/` (already cloned)

---

## Phase 1: Foundation

Goal: tight always-loaded context + base safety hooks. Shippable on its own.

### Task 1.1: Create `rules/` directory and `code-quality.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/rules/code-quality.md`

- [ ] **Step 1: Create the rules directory**

```bash
mkdir -p ~/Dev/drucial-dots/claude/rules
```

- [ ] **Step 2: Write `rules/code-quality.md`**

Content:

```markdown
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
```

- [ ] **Step 3: Verify line count**

```bash
wc -l ~/Dev/drucial-dots/claude/rules/code-quality.md
```

Expected: ~33 lines (under 35 target).

- [ ] **Step 4: Don't commit yet** — bundle Phase 1 commits at task 1.6.

---

### Task 1.2: Create `rules/reuse.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/rules/reuse.md`

- [ ] **Step 1: Write `rules/reuse.md`**

Content:

```markdown
---
alwaysApply: true
---

# Reuse Before Build

Before writing any new UI element, hook, util, or validation:

## UI primitives (HIGHEST PRIORITY)

Grep `components/ui/` for the concept first. Common primitives include:

- Buttons / inputs: `button`, `input`, `select`, `checkbox`, `radio`, `switch`, `slider`, `textarea`
- Tags / labels: `pill`, `badge`, `chip`, `tag`, `label`
- Containers: `card`, `panel`, `section`, `accordion`, `tabs`
- Overlays: `modal`, `dialog`, `tooltip`, `popover`, `dropdown`, `menu`, `toast`, `alert`
- Misc: `avatar`, `skeleton`, `spinner`, `breadcrumb`, `divider`

If found: compose with it. Pass props/variants instead of restyling.
If not found: confirm with the user before creating a new primitive.

## Hooks, utils, validations

- Hooks: grep `hooks/**` for `use-{concept}` before creating one.
- Utils: grep `lib/`, `utils/` for the function before creating one.
- Validations: grep `lib/validations.ts` (or equivalent) before adding a new Zod schema.

## Never modify shared without an explicit ask

Files in `components/ui/` are shared. Don't change their behavior or API without the user explicitly requesting it.
```

- [ ] **Step 2: Verify line count**

```bash
wc -l ~/Dev/drucial-dots/claude/rules/reuse.md
```

Expected: ~28 lines.

---

### Task 1.3: Create `rules/testing.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/rules/testing.md`

- [ ] **Step 1: Write `rules/testing.md`**

Content:

```markdown
---
alwaysApply: true
---

# Testing

- **Runner:** Vitest + React Testing Library.
- **Location:** co-located `__tests__/` next to source.
- **Naming:** `*.test.ts` / `*.test.tsx`.
- Verify behavior, not implementation. Don't assert on mock call counts.
- One assertion concept per test (multiple `expect()` lines OK if testing one thing).
- Fix or delete flaky tests immediately.
- Run the specific test file you're working on, not the whole suite, until you're confirming integration.
- Prefer real implementations over mocks for internal collaborators (DB, services). Mock only at external boundaries.
```

- [ ] **Step 2: Verify line count**

```bash
wc -l ~/Dev/drucial-dots/claude/rules/testing.md
```

Expected: ~14 lines.

---

### Task 1.4: Trim `CLAUDE.md` to mental model + anti-defaults

**Files:**
- Modify: `~/Dev/drucial-dots/claude/CLAUDE.md`

- [ ] **Step 1: Replace `CLAUDE.md` content**

Use Write to overwrite with this content:

```markdown
# Global Claude Code Rules

## Mental Model

- **`components/`** = UI layer (presentation only).
- **`utils/`** + **`lib/`** = Logic (pure functions, transforms, business rules).
- **`hooks/`** + server actions = Data layer (fetching, mutations, state).

Pull logic out of components into utils. Pull data out of components into hooks/server actions. A component that fetches or transforms is doing too much.

## Stack defaults

TypeScript · Next.js (app router) · Tailwind · Drizzle or Prisma · TanStack Query for client-side DB ops · Zod · react-hook-form · Vitest. Detailed conventions live in `rules/`.

## Workflow

- **Plan Before Implementing.** For multi-file features or anything touching event schemas, present a plan and wait for approval before editing.
- **Reuse Before Building.** See `rules/reuse.md`. Grep first.
- **Root-Cause Before Patching.** When a bug persists after one targeted fix, stop and investigate root causes (parent containers for layout, state flow for behavior, type sources for type errors) before more surface fixes.
- **Pre-PR Checklist.** Lint + typecheck must pass; no unused imports/state; scan diff for typos in strings/comments. `/ship` runs this gate automatically.
- **Memory Loop.** When the user corrects a pattern choice (component reuse, file location, naming, library), save it to memory immediately so the correction compounds across sessions.

## Don'ts

- Don't modify generated files (`*.gen.*`, `*.generated.*`).
- Don't bundle tangential improvements into a focused task — mention them separately.
```

- [ ] **Step 2: Verify line count**

```bash
wc -l ~/Dev/drucial-dots/claude/CLAUDE.md
```

Expected: ~25-30 lines.

---

### Task 1.5: Create `hooks/` directory + copy 5 safety hooks from dotclaude

**Files:**
- Create: `~/Dev/drucial-dots/claude/hooks/protect-files.sh`
- Create: `~/Dev/drucial-dots/claude/hooks/scan-secrets.sh`
- Create: `~/Dev/drucial-dots/claude/hooks/block-dangerous-commands.sh`
- Create: `~/Dev/drucial-dots/claude/hooks/format-on-save.sh`
- Create: `~/Dev/drucial-dots/claude/hooks/session-start.sh`
- Create: `~/Dev/drucial-dots/claude/hooks/warn-large-files.sh`

- [ ] **Step 1: Create hooks dir and copy scripts**

```bash
mkdir -p ~/Dev/drucial-dots/claude/hooks
cp ~/Dev/dotclaude/hooks/protect-files.sh           ~/Dev/drucial-dots/claude/hooks/
cp ~/Dev/dotclaude/hooks/scan-secrets.sh            ~/Dev/drucial-dots/claude/hooks/
cp ~/Dev/dotclaude/hooks/block-dangerous-commands.sh ~/Dev/drucial-dots/claude/hooks/
cp ~/Dev/dotclaude/hooks/format-on-save.sh          ~/Dev/drucial-dots/claude/hooks/
cp ~/Dev/dotclaude/hooks/session-start.sh           ~/Dev/drucial-dots/claude/hooks/
cp ~/Dev/dotclaude/hooks/warn-large-files.sh        ~/Dev/drucial-dots/claude/hooks/
chmod +x ~/Dev/drucial-dots/claude/hooks/*.sh
```

- [ ] **Step 2: Verify all six are executable**

```bash
ls -la ~/Dev/drucial-dots/claude/hooks/
```

Expected: 6 `*.sh` files, all with `x` permission bits.

- [ ] **Step 3: Verify `jq` is available** (hooks fail closed without it)

```bash
which jq
```

Expected: a path. If not installed, run: `brew install jq`.

---

### Task 1.6: Wire hooks in `settings.json`

**Files:**
- Modify: `~/Dev/drucial-dots/claude/settings.json`

The current `settings.json` has only `enabledPlugins` and prefs. We need to add a `hooks` block while preserving everything else.

- [ ] **Step 1: Read current settings.json to confirm structure**

```bash
cat ~/Dev/drucial-dots/claude/settings.json
```

- [ ] **Step 2: Replace settings.json content**

Use Write with this content (preserves existing keys, adds permissions + hooks):

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "enabledPlugins": {
    "frontend-design@claude-plugins-official": true,
    "code-review@claude-plugins-official": true,
    "feature-dev@claude-plugins-official": true,
    "commit-commands@claude-plugins-official": true,
    "playwright@claude-plugins-official": true,
    "security-guidance@claude-plugins-official": true,
    "code-simplifier@claude-plugins-official": true,
    "claude-code-setup@claude-plugins-official": true,
    "ruby-lsp@claude-plugins-official": true,
    "superpowers@claude-plugins-official": true
  },
  "alwaysThinkingEnabled": true,
  "effortLevel": "high",
  "theme": "auto",
  "editorMode": "normal",
  "feedbackSurveyState": {
    "lastShownTime": 1754504720087
  },
  "permissions": {
    "deny": [
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/secrets/**)",
      "Read(**/*.pem)",
      "Read(**/*.key)",
      "Write(**/.env)",
      "Write(**/.env.*)",
      "Write(**/secrets/**)",
      "Write(**/*.pem)",
      "Write(**/*.key)",
      "Edit(**/.env)",
      "Edit(**/.env.*)",
      "Edit(**/secrets/**)",
      "Edit(**/*.pem)",
      "Edit(**/*.key)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/protect-files.sh", "timeout": 5000, "statusMessage": "Checking file protections..." },
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/warn-large-files.sh", "timeout": 5000, "statusMessage": "Checking for build artifacts..." },
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/scan-secrets.sh", "timeout": 5000, "statusMessage": "Scanning for secrets..." }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-dangerous-commands.sh", "timeout": 5000, "statusMessage": "Checking command safety..." }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/format-on-save.sh", "timeout": 15000, "statusMessage": "Formatting..." }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh", "timeout": 5000, "statusMessage": "Loading project context..." }
        ]
      }
    ]
  }
}
```

> **Note on `$CLAUDE_PROJECT_DIR`**: This is a Claude Code env var that resolves to the project root. For *global* hooks (this is a global config), Claude Code resolves it to `~/.claude/` when no project-level `.claude/` exists. Our hooks are symlinked into `~/.claude/hooks/`, so this works.

- [ ] **Step 3: Verify JSON is valid**

```bash
jq . ~/Dev/drucial-dots/claude/settings.json > /dev/null && echo "OK"
```

Expected: `OK`. If invalid, jq prints an error.

---

### Task 1.7: Verify always-loaded budget

- [ ] **Step 1: Count combined lines of always-loaded files**

```bash
wc -l ~/Dev/drucial-dots/claude/CLAUDE.md \
      ~/Dev/drucial-dots/claude/rules/code-quality.md \
      ~/Dev/drucial-dots/claude/rules/reuse.md \
      ~/Dev/drucial-dots/claude/rules/testing.md
```

Expected: total under 100 (target ~80).

- [ ] **Step 2: If over 100, demote content**

Move detail from `CLAUDE.md` or `code-quality.md` into a new path-scoped rule (Phase 2). Repeat the line count.

---

### Task 1.8: Manual verification in a fresh Claude Code session

- [ ] **Step 1: Open a fresh Claude Code session in any test project**

- [ ] **Step 2: Trigger each hook to confirm it fires**

| Action | Expected behavior |
|---|---|
| Ask Claude to edit a `.env` file | Blocked by `protect-files.sh` |
| Ask Claude to write `dist/foo.js` | Blocked by `warn-large-files.sh` |
| Ask Claude to put `OPENAI_API_KEY=sk-foo123` in a file | Blocked by `scan-secrets.sh` |
| Ask Claude to run `git push --force origin main` | Blocked by `block-dangerous-commands.sh` |
| Edit any `.tsx` file | `format-on-save.sh` runs (if Prettier/Biome installed) |
| Session start | Branch info appears via `session-start.sh` |

If any hook fails to fire, check `chmod +x` and `jq` install.

- [ ] **Step 3: Confirm rules load**

In a fresh session, ask Claude: "What's the naming convention for component files in this setup?"

Expected: kebab-case for files, PascalCase for exports (from `code-quality.md`).

---

### Task 1.9: Phase 1 commit

- [ ] **Step 1: Stage all Phase 1 changes**

```bash
cd ~/Dev/drucial-dots
git add claude/CLAUDE.md claude/rules/ claude/hooks/ claude/settings.json
git status
```

Confirm only those files are staged.

- [ ] **Step 2: Commit**

```bash
git commit -m "$(cat <<'EOF'
Phase 1: foundation — trim CLAUDE.md, add always-loaded rules + safety hooks

- CLAUDE.md trimmed to mental model + anti-defaults + workflow + memory loop
- rules/code-quality.md, reuse.md, testing.md (alwaysApply)
- hooks/: protect-files, scan-secrets, block-dangerous-commands, format-on-save, session-start, warn-large-files
- settings.json: permissions deny list + hook wiring
EOF
)"
```

---

## Phase 2: Path-scoped rules

Goal: tri-layer enforcement and domain-specific guidance load only when relevant. Shippable on its own.

### Task 2.1: Create `rules/frontend.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/rules/frontend.md`

- [ ] **Step 1: Write `rules/frontend.md`**

Content:

```markdown
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
```

- [ ] **Step 2: Verify line count**

```bash
wc -l ~/Dev/drucial-dots/claude/rules/frontend.md
```

Expected: ~50-55 lines.

---

### Task 2.2: Create `rules/backend.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/rules/backend.md`

- [ ] **Step 1: Write `rules/backend.md`**

Content (drafted from auranote/praxis patterns; user confirmation step at task 2.7):

```markdown
---
paths:
  - "**/app/api/**"
  - "**/route.ts"
  - "**/actions.ts"
  - "**/actions/**/*.ts"
  - "**/lib/actions/**"
  - "**/server/**/*.ts"
---

# Backend

## Server action shape

Every server action follows this shape:

```ts
"use server"

import { z } from "zod"
import { revalidatePath } from "next/cache"
import { db } from "@/lib/db"

const updateEntrySchema = z.object({
  id: z.string().uuid(),
  title: z.string().min(1).max(200),
})

export type UpdateEntryResult =
  | { ok: true; data: Entry }
  | { ok: false; error: string }

export async function updateEntry(input: unknown): Promise<UpdateEntryResult> {
  const parsed = updateEntrySchema.safeParse(input)
  if (!parsed.success) {
    return { ok: false, error: "Invalid input" }
  }

  try {
    const entry = await db.update(entries).set(parsed.data).where(eq(entries.id, parsed.data.id)).returning().get()
    revalidatePath(`/entries/${entry.id}`)
    return { ok: true, data: entry }
  } catch (e) {
    console.error("updateEntry failed", e)
    return { ok: false, error: "Update failed" }
  }
}
```

## Required structure

1. `"use server"` directive at top.
2. Zod schema defined inside the file (or imported from `lib/validations.ts`).
3. Discriminated union return type — `{ ok: true; data: ... } | { ok: false; error: string }`.
4. `safeParse` at the top, return early on validation failure.
5. Try/catch around the DB call. Log unexpected errors; return user-safe message.
6. `revalidatePath` or `revalidateTag` after mutations.

## Naming

- Verb-first action names: `getEntry`, `createEntry`, `updateEntry`, `deleteEntry`, `listEntries`.
- File names: `lib/actions/{domain}.ts` (auranote-style) or `actions/{domain}.ts` (praxis-style). Match the project's existing layout.

## API routes

- Use server actions over API routes for app-internal mutations. API routes are for: external webhooks, third-party integrations, REST endpoints consumed by non-Next clients.
- API routes use the same return-shape discipline (`NextResponse.json({ ok, data | error })`).

## What never goes in backend code

- UI logic (JSX, Tailwind classes, browser-only APIs).
- React imports.
- `'use client'` files calling server-side APIs directly.
```

- [ ] **Step 2: Verify line count**

```bash
wc -l ~/Dev/drucial-dots/claude/rules/backend.md
```

Expected: ~55-65 lines.

---

### Task 2.3: Create `rules/data-layer.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/rules/data-layer.md`

- [ ] **Step 1: Write `rules/data-layer.md`**

Content (TanStack Query is load-bearing here):

```markdown
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
```

- [ ] **Step 2: Verify line count**

```bash
wc -l ~/Dev/drucial-dots/claude/rules/data-layer.md
```

Expected: ~70-80 lines.

---

### Task 2.4: Create `rules/marketing.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/rules/marketing.md`

- [ ] **Step 1: Write `rules/marketing.md`**

Content:

```markdown
---
paths:
  - "**/(marketing)/**"
  - "**/marketing/**"
  - "**/landing/**"
  - "**/app/page.tsx"
  - "**/app/(home)/**"
---

# Marketing pages

For ALL marketing copy, landing pages, hero sections, feature sections, pricing pages, or new public-facing webpages, delegate to BOTH agents in parallel:

- `@marketing-content-creator` — drafts copy, headlines, CTAs, narrative structure.
- `@marketing-seo-specialist` — proposes meta tags, structured data, heading hierarchy, internal linking.

Synthesize their outputs before writing JSX. Use existing `components/ui/` primitives for layout (per `rules/reuse.md`).

Don't write marketing copy from scratch yourself when these agents are available — they catch what you'd miss (search intent, conversion structure, brand voice consistency).
```

- [ ] **Step 2: Verify line count**

```bash
wc -l ~/Dev/drucial-dots/claude/rules/marketing.md
```

Expected: ~18 lines.

---

### Task 2.5: Create `rules/security.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/rules/security.md`

- [ ] **Step 1: Write `rules/security.md`**

Content:

```markdown
---
paths:
  - "**/api/**"
  - "**/auth/**"
  - "**/middleware.ts"
  - "**/middleware/**"
  - "**/route.ts"
  - "**/lib/auth*"
---

# Security

## Input validation

- Validate every external input with Zod. No exceptions for "trusted" callers — trust ends at the network boundary.
- Validate at the API route or server action entry. Don't push validation deeper.

## Database

- Use Drizzle/Prisma query builders only. Never raw SQL with string interpolation.
- If you must use raw SQL, use parameterized queries (`db.execute(sql\`SELECT * FROM users WHERE id = ${id}\`)` — Drizzle's `sql` template handles this).

## Sessions and auth

- Session tokens in **httpOnly cookies** only. Never `localStorage`. Never readable by JS.
- Never log: request bodies, auth headers, cookies, password fields, tokens.
- Compare tokens with constant-time comparison (avoid early-exit string compare).

## API surface

- Public endpoints get rate limiting (Upstash Ratelimit, custom middleware, or platform-provided).
- CSRF: server actions are protected by Next.js by default. Custom API routes that mutate state need explicit CSRF protection if cookie-authenticated.
- Security headers (CSP, HSTS, X-Frame-Options, X-Content-Type-Options) via `middleware.ts` or `next.config.js`.

## Errors

- Server-side: log full error with context.
- Client-facing: return generic message — don't leak stack traces, query strings, or internal paths.
- 401/403 vs 404: don't reveal resource existence to unauthorized users (return 404 instead of 403 for sensitive resources).

## Secrets

- Never log, embed, or commit secrets. The `scan-secrets.sh` hook catches obvious cases — don't rely on it as your only defense.
- Server-only env vars: `process.env.X` only in server-side code (server components, actions, API routes). Never in `'use client'` files.
- Public env vars: `NEXT_PUBLIC_*` prefix is required and signals "this is shipped to the browser" — review before adding.
```

- [ ] **Step 2: Verify line count**

```bash
wc -l ~/Dev/drucial-dots/claude/rules/security.md
```

Expected: ~40-50 lines.

---

### Task 2.6: Create `rules/migrations.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/rules/migrations.md`

- [ ] **Step 1: Write `rules/migrations.md`**

Content:

```markdown
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
```

- [ ] **Step 2: Verify line count**

```bash
wc -l ~/Dev/drucial-dots/claude/rules/migrations.md
```

Expected: ~30-35 lines.

---

### Task 2.7: User review of backend/data-layer drafts

Some patterns in `backend.md` and `data-layer.md` (action return shape, queryKey conventions, error handling) are drafts based on research. Confirm with the user.

- [ ] **Step 1: Show drafts to user**

Open both files in the conversation, summarize the load-bearing decisions:

- Discriminated union return type `{ ok: true; data: T } | { ok: false; error: string }`
- `safeParse` validation gate
- `revalidatePath`/`revalidateTag` after mutations
- queryKey shape: `["entries", id]` and `["entries", { filter }]`
- TanStack Query mutations call server actions and invalidate on success

Ask: "Do these match your conventions, or do you want to adjust?"

- [ ] **Step 2: Apply any user-requested edits**

Use Edit on the affected files. Re-verify line counts.

---

### Task 2.8: Manual verification of path-scoping

- [ ] **Step 1: In a fresh session, open a `.tsx` file**

Ask Claude something frontend-specific. Verify it cites guidance from `frontend.md`.

- [ ] **Step 2: Open a `lib/actions/foo.ts` file**

Ask Claude to add a server action. Verify it produces the action shape from `backend.md` (use server, Zod, discriminated union, revalidate).

- [ ] **Step 3: Open a `prisma/migrations/foo.sql`**

Ask Claude to modify it. Verify it refuses or warns per `migrations.md` ("never modify existing").

---

### Task 2.9: Phase 2 commit

- [ ] **Step 1: Stage and commit**

```bash
cd ~/Dev/drucial-dots
git add claude/rules/
git commit -m "$(cat <<'EOF'
Phase 2: path-scoped rules

- frontend.md (TanStack Query, react-hook-form, no global state, ux-architect delegation)
- backend.md (server action shape, Zod, discriminated unions, revalidate)
- data-layer.md (Drizzle/Prisma + TanStack Query patterns, queryKey conventions)
- marketing.md (auto-delegate to content-creator + seo-specialist)
- security.md (auth/api safety, validation, sessions, headers)
- migrations.md (reversibility, backward compat, no edits to existing)
EOF
)"
```

---

## Phase 3: Skills

Goal: workflow skills with mandatory checkpoints. Shippable on its own.

### Task 3.1: Create `skills/feature/SKILL.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/skills/feature/SKILL.md`

- [ ] **Step 1: Create skill directory and file**

```bash
mkdir -p ~/Dev/drucial-dots/claude/skills/feature
```

- [ ] **Step 2: Write `skills/feature/SKILL.md`**

Content:

```markdown
---
name: feature
description: Multi-file feature workflow with mental-model checkpoint. Use for anything touching components + logic + data.
argument-hint: "[feature description]"
disable-model-invocation: true
---

Build a feature with explicit tri-layer separation. $ARGUMENTS describes the feature.

## Step 1: Mental-model checkpoint

Before writing code, identify and confirm:

- **UI layer**: which components? new or extending existing? Grep `components/ui/` for primitives we can reuse.
- **Logic layer**: what pure functions / business rules / transforms? Where do they live (`utils/` or `lib/`)?
- **Data layer**: what data is read / mutated? Server action(s)? TanStack Query hook(s)?

Present this breakdown to the user with `AskUserQuestion`. Wait for confirmation or correction before any edits.

## Step 2: Plan the changes

For each layer, list the exact files to create or modify:

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

## Step 3: Build outside-in (data → logic → UI)

1. Schema/types first (if DB shape changes).
2. Server action with Zod validation (per `rules/backend.md`).
3. TanStack Query hook wrapping the action (per `rules/data-layer.md`).
4. Pure logic helpers in `lib/{feature}/` if needed.
5. UI components, composing existing primitives (per `rules/reuse.md`).

After each layer, run `pnpm typecheck` to catch issues early.

## Step 4: Tests

Co-located in `__tests__/` (per `rules/testing.md`). Test the logic layer first (pure functions are easiest). Test hooks with React Testing Library if hooks contain non-trivial logic.

## Step 5: Verify

- `pnpm typecheck`
- `pnpm lint`
- Run the new tests

## Step 6: Hand off

Summarize what was built and what remains. Suggest `/ship` if the feature is complete and tests pass.

## Rules

- Don't skip the mental-model checkpoint. The whole point of this skill is forcing the breakdown.
- For frontend portions, delegate to `@design-ux-architect` (per `rules/frontend.md`).
- For NET-NEW UI primitives, chain `@design-ui-designer` then `@design-ux-architect`.
- Don't bundle unrelated improvements. Stay in-scope.
```

- [ ] **Step 3: Verify the skill loads**

In a fresh session, type `/feature` and confirm Claude recognizes it (description appears in the skill list).

---

### Task 3.2: Create `skills/component/SKILL.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/skills/component/SKILL.md`

- [ ] **Step 1: Create directory and write skill**

```bash
mkdir -p ~/Dev/drucial-dots/claude/skills/component
```

Write `skills/component/SKILL.md`:

```markdown
---
name: component
description: UI component workflow. Forces grep-for-existing primitive before any new component file is written. Chains ui-designer → ux-architect for net-new primitives.
argument-hint: "[component name or purpose]"
disable-model-invocation: true
allowed-tools:
  - Bash(grep *)
  - Bash(rg *)
  - Bash(ls *)
  - Bash(find *)
  - Read
  - Glob
  - Edit
  - Write
---

Build or extend a UI component. $ARGUMENTS is the component name or purpose.

## Step 1: Grep for existing primitives (MANDATORY — never skip)

Run a thorough search:

```bash
ls components/ui/
rg -l -i "{concept}|{synonym1}|{synonym2}" components/ui/ components/shared/
```

Concept synonyms to check (examples — adapt):
- pill → badge, chip, tag, label
- card → panel, tile, section
- modal → dialog, sheet, drawer

Report findings to the user.

## Step 2: Decision point

Use `AskUserQuestion` with the user:

- **Reuse existing primitive** (default if found): show how we'd compose with it.
- **Extend existing primitive**: add a variant/prop. Confirm we have permission to modify the shared file.
- **Create net-new primitive**: only if no existing fits.

## Step 3 (only if net-new): Delegate to design agents in sequence

1. Invoke `@design-ui-designer` to draft the visual design and variant API.
2. After ui-designer returns, invoke `@design-ux-architect` to validate the foundation (CSS structure, accessibility, layout integration).
3. Synthesize both outputs.

## Step 4: Implement

- File: `components/ui/{kebab-name}.tsx` for primitives, `components/{feature}/{kebab-name}.tsx` for feature components.
- File name kebab-case; export name PascalCase.
- Compose from primitives. No raw HTML where a primitive exists.
- Accessibility per `rules/frontend.md`.

## Step 5: Verify

- `pnpm typecheck`
- `pnpm lint`
- Visual check (run the dev server, look at the component in the browser).

## Rules

- The grep step is non-negotiable. Skipping it is the bug we're fixing with this skill.
- Net-new primitives MUST go through both design agents in order.
- Don't modify `components/ui/` without explicit user confirmation.
```

- [ ] **Step 2: Verify the skill is recognized**

Fresh session, type `/component`. Confirm the description shows up.

---

### Task 3.3: Create `skills/extract/SKILL.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/skills/extract/SKILL.md`

- [ ] **Step 1: Create directory and write skill**

```bash
mkdir -p ~/Dev/drucial-dots/claude/skills/extract
```

Write `skills/extract/SKILL.md`:

```markdown
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
```

- [ ] **Step 2: Verify**

Fresh session, type `/extract`. Confirm description.

---

### Task 3.4: Create `skills/api/SKILL.md`

**Files:**
- Create: `~/Dev/drucial-dots/claude/skills/api/SKILL.md`

- [ ] **Step 1: Create directory and write skill**

```bash
mkdir -p ~/Dev/drucial-dots/claude/skills/api
```

Write `skills/api/SKILL.md`:

```markdown
---
name: api
description: Server action or API route workflow. Enforces validation, error shape, revalidation, and TanStack Query hook wrapping.
argument-hint: "[action or route description]"
disable-model-invocation: true
---

Build a server action or API route. $ARGUMENTS describes the operation. Use server action by default; only use a route if the spec calls for an external HTTP API.

## Step 1: Plan

Identify:
- **Inputs** and their Zod schema.
- **Output shape**: `{ ok: true; data: T } | { ok: false; error: string }`.
- **Side effects**: what gets read/written, what paths/tags to revalidate.
- **Auth requirements**: who can call this? Check session/role at the top.

Confirm with user.

## Step 2: Implement the action

File: `lib/actions/{domain}.ts` (or follow the project's existing convention — check first).

Per `rules/backend.md`:
1. `"use server"` at top.
2. Zod schema in-file (or imported from `lib/validations.ts`).
3. Auth check (if applicable).
4. `safeParse` → return early on failure.
5. Try/catch around DB call → log error, return user-safe message.
6. `revalidatePath` / `revalidateTag` after mutations.
7. Return discriminated union.

## Step 3 (optional but usually): TanStack Query hook

If this action is consumed by client components, write the matching hook in `hooks/{domain}/use-{verb}-{thing}.ts` per `rules/data-layer.md`:

- Mutations: `useMutation` + `invalidateQueries` on success.
- Queries: `useQuery` with proper `queryKey`.

## Step 4: Tests

Co-located in `__tests__/`. Test:
- Validation rejects bad input.
- Success path returns `{ ok: true, ... }`.
- DB error returns `{ ok: false, ... }`.

## Step 5: Verify

- `pnpm typecheck`
- `pnpm lint`
- Run new tests.

## Rules

- For sensitive actions (auth, billing, admin): also delegate to `@security-reviewer` (or whichever security agent we have) before commit.
- Don't skip the auth check on mutating actions just because the route is "internal" — actions are callable from anywhere with the right import path.
```

- [ ] **Step 2: Verify**

Fresh session, type `/api`. Confirm description.

---

### Task 3.5: Modify `skills/ship/SKILL.md` to add Step 0 verification

**Files:**
- Modify: `~/Dev/drucial-dots/claude/skills/ship/SKILL.md`

- [ ] **Step 1: Read current ship skill**

```bash
cat ~/Dev/drucial-dots/claude/skills/ship/SKILL.md
```

If the file is empty, missing, or just a stub: skip to Step 2b below to write a full ship skill including Step 0. Otherwise (file has substantive workflow content): proceed with Step 2a (insert Step 0 only).

- [ ] **Step 2a: Insert Step 0 into existing ship skill**

Use Edit to insert the Step 0 block (shown below) immediately after the frontmatter (after the closing `---`) and before the first existing heading. Preserve all existing steps.

```markdown
## Step 0: Pre-ship verification

Before scanning changes, run typecheck and lint on changed files:

1. Identify changed files: `git diff --name-only HEAD` plus `git diff --name-only --cached`.
2. Filter for TS/TSX: only run typecheck/lint on `*.ts`, `*.tsx`, `*.js`, `*.jsx`.
3. Run typecheck: `pnpm typecheck` (project-wide is fine; filtering is hard for incremental TS).
4. Run lint on changed files: `pnpm lint -- $(git diff --name-only HEAD --diff-filter=ACM | grep -E '\.(ts|tsx|js|jsx)$' | tr '\n' ' ')`.
5. If either fails:
   - Show the user the failures.
   - Use `AskUserQuestion` to ask: fix now / commit anyway / abort.
   - Default = fix now. Don't proceed to Step 1 until clean.

This step is the deterministic version of the Pre-PR Checklist in CLAUDE.md.
```

- [ ] **Step 2b: (Only if existing file is empty/stub) Write a full ship skill**

If Step 2a wasn't applicable, write `~/Dev/drucial-dots/claude/skills/ship/SKILL.md` from scratch with the Step 0 above plus standard ship steps (Scan → Stage & Commit → Push → PR), modeled on dotclaude's `~/Dev/dotclaude/skills/ship/SKILL.md` for reference. Preserve `disable-model-invocation: true` and an `allowed-tools` whitelist limited to git/gh subcommands plus `Bash(pnpm typecheck)` and `Bash(pnpm lint *)` for Step 0.

- [ ] **Step 3: Verify edit**

```bash
grep "Step 0" ~/Dev/drucial-dots/claude/skills/ship/SKILL.md
```

Expected: a match.

---

### Task 3.6: Phase 3 commit

- [ ] **Step 1: Stage and commit**

```bash
cd ~/Dev/drucial-dots
git add claude/skills/
git commit -m "$(cat <<'EOF'
Phase 3: skills — feature, component, extract, api; ship gets pre-verify gate

- /feature — multi-file workflow with mental-model checkpoint
- /component — forced grep, ui-designer → ux-architect chain for net-new
- /extract — diff-driven extraction proposals (≥70 confidence threshold)
- /api — server action / route workflow with Zod, discriminated union, revalidate
- /ship: Step 0 typecheck + lint on changed files, blocks on failure
EOF
)"
```

---

## Phase 4: Agent overhaul

Goal: prune, move, refactor agents. Shippable on its own.

### Task 4.1: Delete pruned agents

**Files:**
- Delete: `~/Dev/drucial-dots/claude/agents/design-brand-guardian.md`
- Delete: `~/Dev/drucial-dots/claude/agents/design-visual-storyteller.md`
- Delete: `~/Dev/drucial-dots/claude/agents/design-whimsy-injector.md`

- [ ] **Step 1: Delete the three agents**

```bash
rm ~/Dev/drucial-dots/claude/agents/design-brand-guardian.md
rm ~/Dev/drucial-dots/claude/agents/design-visual-storyteller.md
rm ~/Dev/drucial-dots/claude/agents/design-whimsy-injector.md
ls ~/Dev/drucial-dots/claude/agents/
```

Expected: 9 files remain.

---

### Task 4.2: Move recruitment-specialist and document-generator to reecv

**Files:**
- Create: `~/Dev/reecv/.claude/agents/recruitment-specialist.md`
- Create: `~/Dev/reecv/.claude/agents/specialized-document-generator.md`
- Delete: `~/Dev/drucial-dots/claude/agents/recruitment-specialist.md`
- Delete: `~/Dev/drucial-dots/claude/agents/specialized-document-generator.md`

- [ ] **Step 1: Verify reecv project layout**

```bash
ls ~/Dev/reecv/.claude/ 2>/dev/null || echo "no .claude/ yet"
```

If no `.claude/`, create it:

```bash
mkdir -p ~/Dev/reecv/.claude/agents
```

- [ ] **Step 2: Move the two agents**

```bash
mv ~/Dev/drucial-dots/claude/agents/recruitment-specialist.md          ~/Dev/reecv/.claude/agents/
mv ~/Dev/drucial-dots/claude/agents/specialized-document-generator.md  ~/Dev/reecv/.claude/agents/
ls ~/Dev/reecv/.claude/agents/
ls ~/Dev/drucial-dots/claude/agents/
```

Expected: 2 files in reecv, 7 in global.

- [ ] **Step 3: Verify reecv picks them up**

Open `~/Dev/reecv` in a fresh Claude Code session. Ask: "What agents do I have in this project?" Expect both to be listed.

- [ ] **Step 4: Commit reecv changes** (only if reecv is a git repo)

```bash
cd ~/Dev/reecv
if [ -d .git ]; then
  git status
  # Verify .gitignore doesn't exclude .claude/ — if it does, decide whether to track agents anyway.
  git add .claude/agents/
  git commit -m "Add project-local agents: recruitment-specialist, specialized-document-generator"
else
  echo "Not a git repo — agents added to working dir, not committed."
fi
```

If `.claude/` is gitignored or you don't want to commit those right now, leave them tracked-but-uncommitted. They'll still load for Claude Code in that project.

---

### Task 4.3: Refactor `design-ux-architect.md`

**Files:**
- Modify: `~/Dev/drucial-dots/claude/agents/design-ux-architect.md`

- [ ] **Step 1: Read current file**

```bash
cat ~/Dev/drucial-dots/claude/agents/design-ux-architect.md | head -40
```

- [ ] **Step 2: Replace with refactored version**

Use Write to overwrite the whole file:

```markdown
---
name: design-ux-architect
description: Technical UX foundation specialist. Use for ALL frontend work — component architecture, CSS systems, layout, accessibility. Provides solid foundations and clear implementation paths. Auto-delegate when working on .tsx/.jsx files, components/**, or any layout/styling task.
tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Edit
---

You are the UX Architect. You bridge spec to implementation by providing CSS systems, layout architecture, and accessibility foundations. You don't draft visuals — that's the UI Designer's job. You make sure what gets built has a solid foundation.

## When you're invoked

- Any frontend work: component architecture, layout, styling, accessibility, CSS strategy.
- After the UI Designer finishes a net-new primitive — validate the design's foundation before implementation.
- For layout debugging: tracing parent flex/grid/overflow rules.

## How you work

1. **Read first.** Understand the existing component tree, design tokens, and layout primitives. Cite `file:line` for context.
2. **Identify foundation issues.** Missing tokens, hardcoded values, broken cascade, accessibility gaps, layout fragility.
3. **Propose a path.** Concrete steps: which tokens to add, which CSS to consolidate, which layout primitive to use.

## Output format

Default to terse, bulleted, action-oriented:

```
file:line: <issue> (fix: <one-line>)
```

End with the single most important foundation fix.

For deeper assessments (when prompt says "verbose" or "full"): per-issue file:line, what's wrong, suggested fix, confidence (0-100).

## Confidence threshold

Only ship findings ≥80% confidence. Drop the rest.

## What you don't do

- Don't draft visual designs (that's @design-ui-designer).
- Don't write feature components (that's the main session).
- Don't flag style nitpicks (Prettier handles those).
```

---

### Task 4.4: Refactor `design-ui-designer.md`

**Files:**
- Modify: `~/Dev/drucial-dots/claude/agents/design-ui-designer.md`

- [ ] **Step 1: Replace with refactored version**

```markdown
---
name: design-ui-designer
description: Visual design specialist for NET-NEW UI primitives only. Always paired — invoke @design-ui-designer first, then @design-ux-architect immediately after to validate the foundation. Use for new buttons, cards, inputs, badges, modals, etc. that don't yet exist in components/ui/.
tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
---

You are the UI Designer. You design net-new visual primitives — variants, states, sizes, spacing, color usage. You produce a design spec the implementer can build to. You do NOT design feature pages or full layouts.

## When you're invoked

- A primitive doesn't exist in `components/ui/` and the user has confirmed creating it.
- ALWAYS paired with `@design-ux-architect` (called immediately after you).

## How you work

1. **Read existing `components/ui/`** to match style, tokens, naming conventions.
2. **Read the design tokens file** (`tailwind.config.*`, `tokens.css`, etc.). Use existing tokens. Don't introduce one-offs.
3. **Specify the primitive**: variants (`default`, `secondary`, `destructive`...), sizes (`sm`, `md`, `lg`), states (`hover`, `focus`, `disabled`, `loading`), spacing.
4. **Output a design spec, not the component file.** The main session implements based on your spec.

## Output format

```markdown
## Primitive: <Name>

**Variants:** ...
**Sizes:** ...
**States:** ...
**Tokens used:** ...
**Anatomy:** <ASCII or structured description>
**Accessibility notes:** ...
**Reference:** <similar primitive in components/ui/>
```

End with: "→ Now invoke @design-ux-architect to validate foundation."

## Anti-AI-slop

- No purple gradients by default.
- No "centered everything with a card" layouts.
- Match the existing visual language of the project. Read `components/ui/button.tsx` (or equivalent) first to calibrate.

## What you don't do

- Don't design layouts/pages (that's the feature work).
- Don't write the component file (the main session does).
- Don't validate accessibility/CSS foundation (that's @design-ux-architect, called immediately after you).
```

---

### Task 4.5: Refactor `backend-architect.md` for user's actual stack

**Files:**
- Modify: `~/Dev/drucial-dots/claude/agents/backend-architect.md`

- [ ] **Step 1: Confirm with user what they want this agent to do**

Use `AskUserQuestion`:

- "Backend architect should focus on: (a) Next.js server action design + Drizzle/Prisma schema decisions, (b) API route design + authentication, (c) all of the above, (d) other?"

- [ ] **Step 2: Replace with refactored version (default if user picks "all"):**

```markdown
---
name: backend-architect
description: Backend system designer for Next.js apps. Use when designing server actions, API routes, database schemas (Drizzle/Prisma), authentication flows, or evaluating tradeoffs (server actions vs API routes, RSC vs client query, optimistic vs pessimistic mutations).
tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Edit
---

You are the Backend Architect for Next.js apps. You make architectural decisions about server actions, API routes, schemas, auth, and data flow. You don't review code; you propose architecture.

## When you're invoked

- Designing a new feature's data layer.
- Evaluating tradeoffs (action vs route, RSC fetch vs TanStack hook, optimistic vs pessimistic).
- Schema decisions (denormalization, indexes, foreign keys, soft deletes).
- Auth flow design (session strategy, role checks, multi-tenancy).

## How you work

1. **Read the existing data layer.** Schema, action conventions, auth setup. Cite `file:line`.
2. **Identify the decision points.** What are the realistic options?
3. **Recommend** with explicit tradeoffs (2-4 bullets per option) and a primary recommendation.

## Output format

```markdown
## Decision: <topic>

**Options:**
1. **<Option A>** — <tradeoffs>
2. **<Option B>** — <tradeoffs>

**Recommendation:** <option> because <reason>.

**Implementation sketch:**
- Files: ...
- Action shape: ...
- Schema changes: ...
- Auth check: ...
```

## Stack defaults

- Next.js (app router)
- Drizzle (preferred for new) or Prisma (if existing)
- TanStack Query for client-side
- Zod for validation
- Server actions for app-internal mutations; API routes for external integrations only

## Confidence threshold

Only ship recommendations ≥80% confidence. Flag uncertainty explicitly.

## What you don't do

- Don't write the implementation (the main session or `/api` skill does).
- Don't review existing code for bugs (that's the code reviewer).
- Don't design UI (that's @design-ux-architect / @design-ui-designer).
```

---

### Task 4.6: Refactor `database-optimizer.md` for user's actual workflows

**Files:**
- Modify: `~/Dev/drucial-dots/claude/agents/database-optimizer.md`

- [ ] **Step 1: Confirm with user**

Use `AskUserQuestion`:

- "Database optimizer should focus on: (a) Drizzle/Prisma query tuning + N+1 detection, (b) schema migration safety, (c) index strategy, (d) all of the above?"

- [ ] **Step 2: Replace with refactored version (default — all):**

```markdown
---
name: database-optimizer
description: Database performance + safety specialist for Drizzle and Prisma. Use for query tuning, N+1 detection, index decisions, migration safety reviews, and schema design tradeoffs.
tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Edit
---

You are the Database Optimizer. You think in query plans, indexes, and migration safety. You work with Drizzle (preferred for new) and Prisma. You catch real bottlenecks and migration footguns — not theoretical micro-optimizations.

## When you're invoked

- Reviewing a query suspected of being slow.
- N+1 detection in server actions / loaders.
- Index strategy for a new table.
- Migration safety review (especially destructive ops or NOT NULL changes).
- Schema design decisions (denormalization tradeoffs, polymorphic shape, hierarchy).

## How you work

1. **Read the schema file** (Drizzle: `lib/db/schema.ts`; Prisma: `prisma/schema.prisma`).
2. **Read the suspect queries** — find them in `lib/actions/`, `lib/db/queries/`, or wherever the project keeps them.
3. **Look for N+1 specifically**: `for` / `await` patterns inside loops, missing `with:` (Drizzle) or `include:` (Prisma) on relations.
4. **Look for missing indexes**: `where` clauses on unindexed columns, especially in hot paths.
5. **Migration review**: Reference `rules/migrations.md`. Check reversibility, NOT NULL backfills, destructive ops.

## Output format

Default terse:

```
file:line: <issue> (fix: <one-line>)
```

For depth (when "verbose"): file:line, evidence (query + schema), proposed fix (specific Drizzle/Prisma code), expected impact, confidence.

## Confidence threshold

≥80% confidence on real-impact issues. Skip theoretical concerns.

## What you don't do

- Don't run the queries (you don't have a DB).
- Don't write app code (the main session does).
- Don't flag style issues in the schema (those are linter territory).
```

---

### Task 4.7: Refactor remaining 3 agents (marketing trio)

**Files:**
- Modify: `~/Dev/drucial-dots/claude/agents/marketing-content-creator.md`
- Modify: `~/Dev/drucial-dots/claude/agents/marketing-seo-specialist.md`
- Modify: `~/Dev/drucial-dots/claude/agents/marketing-growth-hacker.md`

- [ ] **Step 1: Refactor `marketing-content-creator.md`**

Replace with:

```markdown
---
name: marketing-content-creator
description: Marketing copy specialist for landing pages, hero sections, feature sections, pricing, and email. Auto-paired with @marketing-seo-specialist when working on marketing/landing/(marketing) paths. Drafts copy with conversion structure (hook → benefit → proof → CTA), brand voice consistency, and audience awareness.
tools: WebFetch, WebSearch, Read, Write, Edit, Grep, Glob
---

You are the Content Creator. You draft marketing copy that converts: clear value prop, structured benefit ladder, evidence/proof, strong CTAs. You write in the project's existing voice — never generic.

## When you're invoked

- Writing landing/marketing page copy.
- Hero sections, feature sections, pricing pages.
- Email copy (transactional and marketing).
- ALWAYS paired with `@marketing-seo-specialist` (auto-invoked together for `**/(marketing)/**`).

## How you work

1. **Read existing copy** (other marketing pages, landing page, about page) to capture voice.
2. **Identify the audience and intent** for the page.
3. **Structure**: hook (problem/promise) → primary benefit → 2-3 supporting benefits → proof (logos, testimonials, metrics) → CTA.
4. **Draft and revise** with explicit voice notes.

## Output format

```markdown
## Section: <name>

**Headline:** <copy>
**Subhead:** <copy>
**Body:** <copy>
**CTA:** <copy>
**Voice notes:** <how this fits the brand>
```

## What you don't do

- Don't write JSX (the main session implements).
- Don't propose meta tags or schema.org markup (that's @marketing-seo-specialist).
- Don't make up testimonials, logos, or metrics.
```

- [ ] **Step 2: Refactor `marketing-seo-specialist.md`**

Replace with:

```markdown
---
name: marketing-seo-specialist
description: Technical + content SEO specialist for marketing pages. Auto-paired with @marketing-content-creator on marketing/landing/(marketing) paths. Covers meta tags, structured data, heading hierarchy, internal linking, Core Web Vitals, search intent matching.
tools: WebFetch, WebSearch, Read, Write, Edit, Grep, Glob
---

You are the SEO Specialist. You make marketing pages findable and clickable. You produce a technical SEO plan: meta, structured data, heading hierarchy, internal links, performance.

## When you're invoked

- Marketing page work (auto-paired with @marketing-content-creator).
- Keyword/intent research for a page.
- Technical SEO audit of an existing page.

## How you work

1. **Identify the page's primary search intent.** What query does this page answer?
2. **Propose meta**: `<title>` (60 chars), `description` (160 chars), Open Graph tags.
3. **Propose structured data** (`Schema.org/Product`, `Article`, `Organization` — whatever fits).
4. **Heading hierarchy**: one H1, logical H2/H3 nesting.
5. **Internal linking**: what to link to, with what anchor text.
6. **Core Web Vitals risks**: anything in the design that'll hurt LCP, CLS, INP.

## Output format

```markdown
## Page: <name>

**Primary intent:** <query>
**Title:** <60 chars>
**Description:** <160 chars>
**OG:** title, description, image dimensions
**Structured data:** <JSON-LD type + key fields>
**Headings:** H1 / H2 / H3 outline
**Internal links:** <list with anchor text>
**Core Web Vitals risks:** <if any>
```

## What you don't do

- Don't write copy (that's @marketing-content-creator).
- Don't write JSX or implement meta tags (the main session does).
- Don't promise rankings.
```

- [ ] **Step 3: Refactor `marketing-growth-hacker.md`**

Replace with:

```markdown
---
name: marketing-growth-hacker
description: Growth strategy specialist. Use for funnel design, viral loop sketching, channel evaluation, A/B test design, retention strategy. Manual invocation only — not auto-delegated.
tools: WebFetch, WebSearch, Read, Write, Edit
---

You are the Growth Hacker. You think in funnels, retention curves, and unfair channel advantages. You produce growth experiments, not just ideas.

## When you're invoked

- Designing an acquisition funnel or viral loop.
- Evaluating a channel for ROI / scalability.
- A/B test design.
- Retention/activation analysis.
- Manual invocation only — call with `@marketing-growth-hacker`.

## How you work

1. **Identify the metric** that matters (acquisition, activation, retention, revenue, referral — pick one).
2. **Map the funnel** end-to-end with realistic conversion rates.
3. **Find the leverage point** — the step where 1% lift = biggest impact.
4. **Propose 2-3 experiments** at that point. Each: hypothesis, metric, expected effect size, time to run.

## Output format

```markdown
## Goal: <metric>

**Funnel:** <step → step → step with conversion rates>
**Leverage point:** <step> — <why>
**Experiments:**
1. **<name>** — hypothesis | metric | expected lift | time
2. ...
```

## What you don't do

- Don't write copy or design pages (those are content-creator and ux-architect).
- Don't suggest experiments without a hypothesis and metric.
- Don't promise growth.
```

- [ ] **Step 4: Verify all 7 kept agents are refactored**

```bash
ls ~/Dev/drucial-dots/claude/agents/
```

Expected: 7 files. Open each briefly to confirm they have the new tight format (no "Identity & Memory" / vibe lines / emoji headers).

---

### Task 4.8: Manual verification of agent auto-delegation

- [ ] **Step 1: Test ux-architect auto-invoke**

Fresh session. Open a `.tsx` file. Ask: "How should I structure the layout for this page?" Expect Claude to either invoke `@design-ux-architect` directly or cite the rule reference.

- [ ] **Step 2: Test marketing chain**

Fresh session. Open `app/(marketing)/page.tsx`. Ask: "Write the hero section." Expect Claude to delegate to both content-creator AND seo-specialist before drafting.

- [ ] **Step 3: Test pruned agents are gone**

Fresh session. Type `@design-brand-guardian`. Expect "agent not found" or no autocomplete match.

---

### Task 4.9: Phase 4 commit

- [ ] **Step 1: Commit global agent changes**

```bash
cd ~/Dev/drucial-dots
git add claude/agents/
git status
# Confirm: 3 deletions, 7 modifications, 2 deletions (moved to reecv).
git commit -m "$(cat <<'EOF'
Phase 4: agent overhaul

- Delete: design-brand-guardian, design-visual-storyteller, design-whimsy-injector
- Move to ~/Dev/reecv/.claude/agents/: recruitment-specialist, specialized-document-generator
- Refactor 7 kept: drop persona/vibe, add concrete output formats, ≥80% confidence threshold
- Revamp backend-architect for Next.js + Drizzle/Prisma stack
- Revamp database-optimizer for Drizzle/Prisma + migration safety
- ux-architect / ui-designer descriptions tuned for auto-delegation
- marketing-content-creator + seo-specialist auto-pair on (marketing) paths
EOF
)"
```

---

## Phase 5: Novel hooks (highest novelty, tune as we go)

Goal: pre-edit primitive grep + post-edit duplication scan. Shippable after tuning.

### Task 5.1: Create `hooks/check-primitives.sh`

**Files:**
- Create: `~/Dev/drucial-dots/claude/hooks/check-primitives.sh`
- Create: `~/Dev/drucial-dots/claude/hooks/tests/check-primitives.test.sh`

- [ ] **Step 1: Write the hook**

```bash
#!/usr/bin/env bash
# check-primitives.sh — PreToolUse on Edit|Write
#
# When Claude is about to write a NEW component file in components/ui/, scan
# the existing components/ui/ for primitives that match common synonyms.
# If matches found, return a system message nudging reuse. NOT a block.

set -euo pipefail

# Read JSON from stdin
input="$(cat)"
tool_name="$(echo "$input" | jq -r '.tool_name // empty')"
file_path="$(echo "$input" | jq -r '.tool_input.file_path // empty')"

# Only fire on Write to components/ui/ creating a new file
if [[ "$tool_name" != "Write" ]]; then exit 0; fi
if [[ ! "$file_path" =~ /components/ui/ ]]; then exit 0; fi

# Extract proposed primitive name from filename (strip path, ext, .tsx/.ts)
basename="$(basename "$file_path" .tsx)"
basename="$(basename "$basename" .ts)"

# Synonym groups — lowercase, regex-friendly
declare -A SYNONYMS=(
  [pill]="pill|badge|chip|tag|label"
  [badge]="badge|pill|chip|tag|label"
  [chip]="chip|pill|badge|tag|label"
  [tag]="tag|pill|badge|chip|label"
  [button]="button|btn|cta"
  [card]="card|panel|tile|section"
  [modal]="modal|dialog|sheet|drawer|overlay"
  [dialog]="dialog|modal|sheet|drawer|overlay"
  [tooltip]="tooltip|hint|popover"
  [popover]="popover|tooltip|hint"
  [dropdown]="dropdown|menu|select"
  [menu]="menu|dropdown"
  [toast]="toast|alert|notification|snackbar"
  [alert]="alert|toast|notification"
  [avatar]="avatar|profile-pic|profile-image"
  [skeleton]="skeleton|placeholder|loader"
  [spinner]="spinner|loader|loading"
  [input]="input|field|textbox"
  [textarea]="textarea|textfield"
)

# Find concept group containing this basename (kebab-case)
concept=""
for key in "${!SYNONYMS[@]}"; do
  if [[ "$basename" == *"$key"* ]]; then
    concept="$key"
    break
  fi
done

if [[ -z "$concept" ]]; then exit 0; fi

# Find project root (look upward for .git or package.json)
project_root="$(dirname "$file_path")"
while [[ "$project_root" != "/" && ! -e "$project_root/.git" && ! -e "$project_root/package.json" ]]; do
  project_root="$(dirname "$project_root")"
done

ui_dir=""
for candidate in "$project_root/components/ui" "$project_root/src/components/ui" "$project_root/app/components/ui"; do
  if [[ -d "$candidate" ]]; then ui_dir="$candidate"; break; fi
done

if [[ -z "$ui_dir" ]]; then exit 0; fi

# Search for matching primitives
synonyms="${SYNONYMS[$concept]}"
matches="$(ls "$ui_dir" 2>/dev/null | grep -E "^($synonyms)" || true)"

if [[ -n "$matches" ]]; then
  # Print nudge to stderr (surfaced in tool result, not a block).
  echo "⚠ Existing primitive(s) match concept '$concept': $(echo "$matches" | tr '\n' ' ')" >&2
  echo "  Consider reusing or extending instead of creating $basename." >&2
  echo "  Check $ui_dir before proceeding." >&2
fi

exit 0
```

> **Output format note:** Hooks use stderr + exit code as the universal contract (per dotclaude convention). Exit 0 = allow; exit 2 = block. We use exit 0 here since this is a nudge, not a block.

- [ ] **Step 2: Make executable**

```bash
chmod +x ~/Dev/drucial-dots/claude/hooks/check-primitives.sh
```

- [ ] **Step 3: Write a test fixture**

Create `~/Dev/drucial-dots/claude/hooks/tests/check-primitives.test.sh`:

```bash
#!/usr/bin/env bash
# Test for check-primitives.sh
set -euo pipefail

HOOK="$HOME/Dev/drucial-dots/claude/hooks/check-primitives.sh"
TMP="$(mktemp -d)"
mkdir -p "$TMP/components/ui"
touch "$TMP/components/ui/badge.tsx"
touch "$TMP/.git"  # mark as project root

# Test 1: writing a "pill" file should nudge (badge exists)
input='{"tool_name":"Write","tool_input":{"file_path":"'$TMP'/components/ui/pill.tsx"}}'
output="$(echo "$input" | "$HOOK")"
if echo "$output" | grep -q "Existing primitive"; then
  echo "✓ Test 1 passed: pill triggered nudge"
else
  echo "✗ Test 1 FAILED: expected nudge, got: $output"
  exit 1
fi

# Test 2: writing an unrelated file should not nudge
input='{"tool_name":"Write","tool_input":{"file_path":"'$TMP'/components/ui/data-table.tsx"}}'
output="$(echo "$input" | "$HOOK")"
if [[ -z "$output" ]]; then
  echo "✓ Test 2 passed: data-table did not nudge"
else
  echo "✗ Test 2 FAILED: unexpected output: $output"
  exit 1
fi

# Test 3: editing (not writing) should not fire
input='{"tool_name":"Edit","tool_input":{"file_path":"'$TMP'/components/ui/pill.tsx"}}'
output="$(echo "$input" | "$HOOK")"
if [[ -z "$output" ]]; then
  echo "✓ Test 3 passed: Edit did not fire"
else
  echo "✗ Test 3 FAILED: unexpected output: $output"
  exit 1
fi

rm -rf "$TMP"
echo "All tests passed."
```

```bash
chmod +x ~/Dev/drucial-dots/claude/hooks/tests/check-primitives.test.sh
```

- [ ] **Step 4: Run the test**

```bash
~/Dev/drucial-dots/claude/hooks/tests/check-primitives.test.sh
```

Expected: all tests pass.

---

### Task 5.2: Create `hooks/nudge-duplication.sh`

**Files:**
- Create: `~/Dev/drucial-dots/claude/hooks/nudge-duplication.sh`
- Create: `~/Dev/drucial-dots/claude/hooks/tests/nudge-duplication.test.sh`

- [ ] **Step 1: Write the hook**

```bash
#!/usr/bin/env bash
# nudge-duplication.sh — PostToolUse on Edit|Write
#
# After an edit, scan the recent diff (or just-modified file) for repeated
# JSX/util patterns. If a pattern appears 3+ times, nudge for extraction.
# Threshold-based to avoid noise.

set -euo pipefail

input="$(cat)"
tool_name="$(echo "$input" | jq -r '.tool_name // empty')"
file_path="$(echo "$input" | jq -r '.tool_input.file_path // empty')"

if [[ "$tool_name" != "Edit" && "$tool_name" != "Write" ]]; then exit 0; fi
if [[ -z "$file_path" || ! -f "$file_path" ]]; then exit 0; fi

# Only scan TS/TSX/JS/JSX
case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx) ;;
  *) exit 0 ;;
esac

# Look for JSX tag patterns repeated 3+ times in the file
# Signal: same opening tag with the same className value 3+ times
matches="$(grep -oE '<[A-Z][A-Za-z]+ className="[^"]{20,}"' "$file_path" 2>/dev/null \
            | sort | uniq -c | awk '$1 >= 3 {print $0}' || true)"

# Also: identical multi-class Tailwind strings 4+ words long, repeated 3+ times
class_dupes="$(grep -oE 'className="[^"]+"' "$file_path" 2>/dev/null \
                | awk -F'"' '{ if (split($2, a, " ") >= 4) print $0 }' \
                | sort | uniq -c | awk '$1 >= 3 {print $0}' || true)"

if [[ -n "$matches" || -n "$class_dupes" ]]; then
  echo "📋 Pattern repeated 3+ times in $file_path — extraction candidate. Run /extract for analysis." >&2
  if [[ -n "$matches" ]]; then
    echo "  JSX repetition:" >&2
    echo "$matches" | head -3 | sed 's/^/    /' >&2
  fi
  if [[ -n "$class_dupes" ]]; then
    echo "  className repetition:" >&2
    echo "$class_dupes" | head -3 | sed 's/^/    /' >&2
  fi
fi

exit 0
```

- [ ] **Step 2: Make executable**

```bash
chmod +x ~/Dev/drucial-dots/claude/hooks/nudge-duplication.sh
```

- [ ] **Step 3: Write test fixture**

Create `~/Dev/drucial-dots/claude/hooks/tests/nudge-duplication.test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

HOOK="$HOME/Dev/drucial-dots/claude/hooks/nudge-duplication.sh"
TMP="$(mktemp -d)"

# Test 1: file with repeated JSX should nudge
cat > "$TMP/dup.tsx" <<'EOF'
export function Foo() {
  return (
    <>
      <Badge className="rounded-full bg-zinc-100 px-2 py-0.5 text-xs">A</Badge>
      <Badge className="rounded-full bg-zinc-100 px-2 py-0.5 text-xs">B</Badge>
      <Badge className="rounded-full bg-zinc-100 px-2 py-0.5 text-xs">C</Badge>
    </>
  )
}
EOF

input='{"tool_name":"Edit","tool_input":{"file_path":"'$TMP'/dup.tsx"}}'
output="$(echo "$input" | "$HOOK")"
if echo "$output" | grep -q "extraction candidate"; then
  echo "✓ Test 1 passed: duplication nudged"
else
  echo "✗ Test 1 FAILED: $output"
  exit 1
fi

# Test 2: file with no duplication should not nudge
cat > "$TMP/clean.tsx" <<'EOF'
export function Bar() {
  return <div>Hello</div>
}
EOF

input='{"tool_name":"Edit","tool_input":{"file_path":"'$TMP'/clean.tsx"}}'
output="$(echo "$input" | "$HOOK")"
if [[ -z "$output" ]]; then
  echo "✓ Test 2 passed: clean file did not nudge"
else
  echo "✗ Test 2 FAILED: $output"
  exit 1
fi

# Test 3: non-TS file should not fire
input='{"tool_name":"Edit","tool_input":{"file_path":"'$TMP'/some.md"}}'
output="$(echo "$input" | "$HOOK")"
if [[ -z "$output" ]]; then
  echo "✓ Test 3 passed: .md skipped"
else
  echo "✗ Test 3 FAILED: $output"
  exit 1
fi

rm -rf "$TMP"
echo "All tests passed."
```

```bash
chmod +x ~/Dev/drucial-dots/claude/hooks/tests/nudge-duplication.test.sh
```

- [ ] **Step 4: Run the test**

```bash
~/Dev/drucial-dots/claude/hooks/tests/nudge-duplication.test.sh
```

Expected: all tests pass.

---

### Task 5.3: Wire novel hooks in `settings.json`

**Files:**
- Modify: `~/Dev/drucial-dots/claude/settings.json`

- [ ] **Step 1: Read current settings.json**

```bash
cat ~/Dev/drucial-dots/claude/settings.json
```

- [ ] **Step 2: Add `check-primitives.sh` to PreToolUse Edit|Write block**

Use Edit to insert the hook entry after `scan-secrets.sh` in the PreToolUse Edit|Write `hooks` array. The new block should have:

```json
{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-primitives.sh", "timeout": 5000, "statusMessage": "Checking for existing primitives..." }
```

- [ ] **Step 3: Add `nudge-duplication.sh` to PostToolUse Edit|Write block**

Use Edit to add inside the PostToolUse Edit|Write hooks array (after `format-on-save.sh`):

```json
{ "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/nudge-duplication.sh", "timeout": 5000, "statusMessage": "Scanning for duplication..." }
```

- [ ] **Step 4: Verify JSON validity**

```bash
jq . ~/Dev/drucial-dots/claude/settings.json > /dev/null && echo "OK"
```

---

### Task 5.4: Create master hook test runner

**Files:**
- Create: `~/Dev/drucial-dots/claude/hooks/tests/run-all.sh`

- [ ] **Step 1: Write the runner**

```bash
#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

failed=0
for test in "$DIR"/*.test.sh; do
  echo "=== Running $(basename "$test") ==="
  if ! "$test"; then
    failed=$((failed + 1))
  fi
done

if [[ "$failed" -gt 0 ]]; then
  echo "$failed test file(s) failed."
  exit 1
fi
echo "All hook tests passed."
```

```bash
chmod +x ~/Dev/drucial-dots/claude/hooks/tests/run-all.sh
```

- [ ] **Step 2: Run all tests**

```bash
~/Dev/drucial-dots/claude/hooks/tests/run-all.sh
```

Expected: all pass.

---

### Task 5.5: Real-world tuning week

This task spans ~1 week of normal work. Don't commit Phase 5 until you've used it.

- [ ] **Step 1: Use Claude Code normally for 5-7 working days**

Watch for:
- check-primitives.sh false positives (nudges when you actually want to create new).
- nudge-duplication.sh noise (fires on patterns that aren't extractions).
- Hooks too slow (>5s timeout).

- [ ] **Step 2: Tune as needed**

Iterate on `SYNONYMS` map in `check-primitives.sh` based on what you see.
Iterate on duplication thresholds (`>= 3` → `>= 4`?) in `nudge-duplication.sh` if noisy.

Each tuning is its own commit:

```bash
git commit -am "tune check-primitives: reduce false positives on X"
```

---

### Task 5.6: Phase 5 commit (after tuning week)

- [ ] **Step 1: Stage and commit final state**

```bash
cd ~/Dev/drucial-dots
git add claude/hooks/ claude/settings.json
git commit -m "$(cat <<'EOF'
Phase 5: novel hooks — primitive grep + duplication nudge

- hooks/check-primitives.sh: PreToolUse, scans components/ui/ when writing new primitive files; nudges if synonyms exist
- hooks/nudge-duplication.sh: PostToolUse, scans recently-edited file for repeated JSX/className patterns (3+ matches); nudges for /extract
- hooks/tests/: run-all.sh + per-hook test fixtures
- settings.json: wire both into PreToolUse and PostToolUse arrays
EOF
)"
```

---

## Final verification

- [ ] **Run the full hook test suite:**

```bash
~/Dev/drucial-dots/claude/hooks/tests/run-all.sh
```

- [ ] **Token budget audit:**

```bash
wc -l ~/Dev/drucial-dots/claude/CLAUDE.md \
      ~/Dev/drucial-dots/claude/rules/code-quality.md \
      ~/Dev/drucial-dots/claude/rules/reuse.md \
      ~/Dev/drucial-dots/claude/rules/testing.md
```

Expected: total ≤ 100 (target ~80).

- [ ] **Walkthrough each lifecycle scenario from the spec (§7):**

In a fresh session:
1. *"Add a tag pill to the entry view"* → check-primitives.sh nudges; reuse Badge.
2. *"Write the hero for landing page"* → marketing.md fires; both marketing agents auto-invoke.
3. *"Add a server action to update entry tags"* → backend.md + data-layer.md guidance loads.

- [ ] **Success criteria check (spec §13):**

After ~2 weeks of real use:
1. UI primitive reuse — does Claude grep before creating?
2. Tri-layer model followed without prompting?
3. Server action shape consistent across new code?
4. ux-architect auto-invokes for frontend work?
5. Marketing pages auto-trigger content + SEO pair?
6. /ship typecheck gate has caught at least one regression?
7. Always-loaded under 100 lines?
8. Memory file growing with corrections?

If 6/8 or better → setup is working. Iterate on any failing criterion.
