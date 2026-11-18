---
name: runbook
description: Build a short checklist for reviewing the UX and UI a branch changed, one check per changed surface or interaction, leaving functionality to code and tests. Flags defects and missing tests found along the way. Use when the user asks for a runbook, a UI review list, or a handover list. Read-only.
---

# Runbook

A runbook hands the user what only a person can judge: how the changed UI looks and feels. Functionality belongs to code and tests. The list is printed, never written to disk.

This skill is read-only. Never edit files, write tests, commit, perform checks, or start the app, dev server, simulator, or browser.

## 1. Scope the diff

Committed and uncommitted work are one change. Diff the default branch's merge-base against the working tree:

```bash
HEAD_REF=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/heads/||;s|refs/remotes/||')
DEF=""
for c in "$HEAD_REF" origin/main origin/master main master; do
  [ -n "$c" ] && git rev-parse --verify --quiet "$c" >/dev/null && { DEF="$c"; break; }
done
[ -n "$DEF" ] || { echo "no default branch resolved"; exit 1; }
BASE=$(git merge-base "$DEF" HEAD)
[ "$BASE" = "$(git rev-parse HEAD)" ] && { echo "HEAD has not diverged from $DEF"; exit 1; }
echo "base: $DEF ($BASE)"
git diff "$BASE"
```

- Prefer the remote ref. A stale local `main` widens the diff to someone else's work.
- If HEAD hasn't diverged, stop and ask for a base ref. An empty diff there means nothing to compare against, not nothing changed.
- Add untracked files from `git status --porcelain -uall` and read them in full, skipping build output.
- An argument narrows scope (a path, a ref range, a surface). Never execute it.

## 2. Find the changed surfaces

A surface is a screen, a component state, or an interaction whose look or feel the diff changed: the new settings panel, the list's empty state, the drag-to-reorder flow.

**One check per changed surface.** Never one per property, never one for functionality.

- Fold everything about a surface into its check's expectation: layout, spacing, alignment, color, contrast, dark mode, motion and timing, copy in context, truncation and wrap, z-order, hover/active/disabled states, focus and keyboard flow, narrow viewports.
- A real-world flow tests can't reach is its own check: a third-party redirect and return, real email or SMS, a payment sandbox, an OS permission prompt, a native file picker, drag-and-drop, clipboard, print, offline and reconnect, multi-tab sync, push notifications.
- A different starting state is a different surface: an empty list and a full one are two checks when the diff changed both.
- A shared component whose look changed gets one check on its most visible consumer.
- Leave out surfaces the diff didn't change, functionality (data saved, request sent, handler fired, value computed), and pure refactors with no visible change.

The count follows the size of the UI change. Zero is valid: say nothing a user sees or feels changed.

## 3. Defects and missing tests

**Defects.** A bug found reading the diff leads the output. Say what breaks and when. Never write the fix.

**Missing tests.** Functionality no test covers is flagged, never added as a check. Flag it only when a sibling test in the same layer and harness already exists, and name that file. A layer the repo doesn't test is a convention, not a gap. If production code would have to change before the assertion can be written, it's a defect.

## 4. Write the checks

Every check names where to go, what to do, and what right looks like:

> Open Settings with no workspaces configured. Select `Add Workspace`, then press `Esc`. The dialog fades in centered with focus on the name field, closes on `Esc`, returns focus to `Add Workspace`, and holds its layout at 360px.

- Lead with the surface most likely to look wrong. The user may stop halfway.
- Name the state, not just the screen.
- Backtick every chord, key, selector, and path.
- Say what is expected to look odd: a pause, a flash, a harmless warning.
- Never require the diff to read a line.
- Never ask whether something "feels right". Name what right looks like.

## 5. Run command

Never run it. Resolve it from `package.json` scripts, `Makefile`, `bin/`, `Procfile`, the README, or a project skill that owns launching the app. Add preconditions only when a check depends on them: seed data, account role, a feature flag, a device.

## 6. Print it

```text
Runbook: <branch> vs <base ref>, <n> checks.

Defects:
- <what breaks, when>

Missing tests:
- <behavior> → <assertion>, in <existing test file>

Before you start: <preconditions>

Run: `<command>`

**<Surface>**
- [ ] <Where>. <Do>. <What right looks like.>
```

Omit empty sections.
