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
