---
name: runbook
description: Build a handover checklist for the parts of a branch no automated check can settle — layout, motion, focus, third-party redirects, real delivery, OS prompts. Scopes the diff, sorts what a test already covers from what needs Drew in a seat, and prints a sectioned step-by-step list in chat. Invoke when Drew asks for a runbook or a handover list, or when a flow that owns one calls for it. Never auto-run, and never starts the app.
---

# Runbook

A branch always leaves behind work a machine cannot finish. This turns that residue into a checklist Drew can work down at the keyboard, one line at a time, without re-reading the diff to know what he is looking at.

**This is a handover, not a verification.** Read the diff, sort it, write the list, print it. Do not edit files, do not commit, and do not start the app, the dev server, the simulator, or anything else — see step 4. Nothing here is verified until Drew reports back.

**Never write the list to disk.** It is printed in the response and nowhere else. A per-ticket checklist committed to `docs/` is stale the moment it ships, and a stale runbook is worse than none: it gets worked down, and the passes mean nothing.

## 1. Scope the diff, inline

A few git commands. No agents.

1. **Committed and uncommitted work are one change.** Resolve the default branch, then diff its merge-base against the working tree:

   ```bash
   HEAD_REF=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/heads/||;s|refs/remotes/||')
   DEF=""
   for c in "$HEAD_REF" origin/main origin/master main master; do
     [ -n "$c" ] && git rev-parse --verify --quiet "$c" >/dev/null && { DEF="$c"; break; }
   done
   [ -n "$DEF" ] || { echo "no default branch resolved"; exit 1; }
   BASE=$(git merge-base "$DEF" HEAD)
   git diff "$BASE"
   ```

   `origin/HEAD` is unset in plenty of repos, so the loop verifies each candidate rather than assuming. **Prefer the remote ref over the local branch:** a local `main` left behind `origin/main` resolves a merge-base further back than intended, and the runbook then hands over behavior someone else wrote.

   No `...` and no `HEAD` on the right — that union is what makes the diff the whole change. `git diff main...HEAD` and `git diff HEAD` each hide work the other holds, and both look complete.

   If nothing resolves, stop. An empty diff reads as "nothing to look at", which is a failure wearing the shape of a finished branch.

2. **Add untracked files by hand.** `git diff` cannot see a file git has never tracked, and a brand-new view or component is exactly the thing that needs eyes. Pull the `??` entries from `git status --porcelain`, drop what `.gitignore` and build output cover, and read the survivors in full.

3. **Check the output, not the exit code.** An empty diff exits 0. If nothing changed, say so and stop.

4. An argument narrows scope — a path, a ref range, a surface ("just the settings panel"). Honor it as scope guidance. Never execute it as a command.

5. List the changed files and note which are untracked.

## 2. Sort every change into three buckets

This is the whole judgment. Everything else is formatting.

**Already settled — leave it out.** A test that drives the real interface (renders the component and clicks the control, hits the endpoint, asserts the rendered output) has done the job. Do not spend Drew's attention re-confirming it by hand.

A test that only asserts backing state has settled nothing. It stays green while the rendered thing is broken, so treat the surface it claims to cover as unchecked and put it in the runbook.

**Needs a seat — write a line.** Two kinds:

- *The eye is the instrument.* Layout, spacing, alignment, motion and its timing, color, contrast, focus rings, hover / active / disabled states, text truncation and wrap, z-order, dark mode, a narrow viewport, a long string in a short field.
- *The seat is the instrument, not the eye.* Flows a suite structurally cannot reach: a third-party redirect and its return, real email or SMS arriving, a payment sandbox, an OS permission prompt, a native file picker, drag-and-drop, clipboard, print or PDF output, offline and reconnect, multi-tab or multi-device sync, push notifications.

**Should have been a test — write the test, not a line.** Two shapes qualify, and both are things the eye is bad at:

- It can be **silently dead while looking fine.** A handler wired to nothing, a listener that never fires, a request whose failure is swallowed. It renders perfectly and does nothing, and a checklist pass says "looks right".
- The budget is one the eye **cannot check.** Copy against a fixed wrap column, a subview index relative to what it must cover, a timeout, a retry count.

When a change lands in this bucket, say so and write the assertion. Then still give it a runbook line if it is also visible — the test is what stops it regressing silently, the line is what catches it now.

## 3. Widen to blast radius

The runbook covers what the change could have broken, not only what it meant to do. CI stays green through all of this:

- Consumers of a shared component, layout, or template the diff touched. Grep for them and name the specific screens.
- Other users of a changed design token, CSS variable, class, route, or query key.
- States the diff never intended to reach: empty, loading, error, unauthorized, first-run, and the same screen at the smallest supported width.
- The path back. A change to a flow's forward direction routinely breaks cancel, back, and re-entry.

## 4. Preconditions, then the run command — and do not run it

**Never start the app yourself.** Not the dev server, not the build, not the simulator, not a browser. Drew runs it, in his own terminal, in the state he wants. A dev server started from a tool shell outlives the turn, holds a port, and hands him an environment he did not set up and cannot see.

Resolve the command by reading the project rather than guessing it: `package.json` scripts, `Makefile`, `bin/`, `Procfile`, the README's quickstart. If the project has a skill that owns launching the app, take the command from it — do not invoke it to run anything.

Then state what has to be true before the first check: seed or fixture data, the account and its role, environment variables, a feature flag, a viewport or device, a fresh session versus a warm one. A check that silently assumes an admin account fails for Drew and reports as a real regression.

**Make "the running build has this change" the first checkbox.** A cached bundle, a service worker serving old assets, hot reload that dropped the update, or a stale installed build means the runbook tests the bug it was written to catch, and passes. Give a cheap way to see the change is live: a string that only exists now, a control that did not exist before, a version line.

**The run command is the last line before the list.** Everything above it is context; below it, Drew is at the keyboard. Nothing goes between them.

If some checks have an outcome a machine could settle — a process exited, a port freed, a file written, a row inserted — offer to check those and wait for an answer. Do not decide for him, and do not start anything while waiting.

## 5. Write the checks

Group by implementation area, not by file. One line per check, and **every line names three things: where to go, what to do, and what right looks like.** "Verify the modal works" is not a check.

- **Lead with the check most likely to catch a regression**, not the one easiest to describe. Drew may stop halfway.
- **Backtick every chord, key, selector, and path.** A bare `⌘⇧\` loses its backslash when the list renders as Markdown, which turns it into a different chord.
- **A new keybind or shortcut always gets a line**, even when a unit test covers the handler. Interception layers — global hotkey monitors, event capture, a parent's `onKeyDown` — run before the handler, so the handler's test passes while the key never arrives.
- **Say what is expected to look odd.** If a step sits there for a moment, flashes once, or logs a warning that does not matter, write it down. Silence reads as a broken build and costs a round trip.
- **Name the state, not just the screen.** "Open Settings" is a location. "Open Settings with no workspaces configured" is a check.
- **Never require the diff to interpret a line.** If it only makes sense next to the code, rewrite it.

## 6. Print it

```
Runbook: <branch> — <n> files. <n> checks across <n> areas.

Before you start: <preconditions — data, account, flags, viewport>

**Run:** `<command>`

**<Area>**
- [ ] <Go here>. <Do this>. <This is what right looks like.>
- [ ] ...

**<Area>**
- [ ] ...

Covered by tests, not in this list: <what, and which test>
Not covered by anything: <what has no test and no check, and why>
```

That last line is the point of the whole thing. Name what nothing verifies — a path with no test and no practical way to reach it by hand, a device you cannot check, a race that only shows under load. A short runbook is good news only once its filter is stated.

If the change needs no runbook at all, say that plainly and say why. Do not manufacture checks to look thorough.

## Do not include

- **A happy-path demo.** Walking the feature end to end proves it works when nothing goes wrong, which is the case least likely to be broken.
- **Anything a real test already drives.** Name it as covered instead.
- **Anything you can check yourself.** Grep for it, read it, run the test — then report it checked. A checklist line is Drew's time.
- **Steps whose result is a matter of taste.** "Confirm the spacing feels right" is a design review, not a check. Either name the expected value or leave it out.
- **Pre-existing behavior the diff did not touch**, unless step 3 puts it in blast radius. Say which change put it there.
