---
name: interactive-runbook
description: Work through manual verification with Drew one check at a time. Use when Drew asks to run, execute, walk through, or complete a runbook interactively; when a shipping flow reaches GUI verification; or when filesystem, Git, browser, app, device, focus, layout, motion, or timing behavior needs a person observing a live build. Never synthesize input or run unattended.
---

# Interactive Runbook

Turn a manual checklist into a shared live session. Drew owns the running app and what his eyes report. You own sequencing, controlled fixtures, result tracking, and cleanup.

## Prepare

1. Use an existing runbook when one is already in the conversation. Otherwise invoke the global `runbook` skill to derive the checks.
2. Remove checks already settled by a real interaction test. Keep anything needing eyes, a real device, OS behavior, or a live external system.
3. Order checks by dependency and risk. Put setup before the behavior it enables, but lead with the most failure-prone behavior once ready.
4. State the required build or server and ask Drew to start it. Never start or restart it yourself unless he explicitly asks.
5. Keep the checklist in conversation state. Never write a per-run runbook to disk.

## Run one check per turn

For each check:

1. Name the current check and its expected result in one or two sentences.
2. Perform at most one controlled tool-side action when the check needs it, such as:
   - edit a fixture file;
   - stage or unstage a known file;
   - create a disposable branch or worktree;
   - change bounded test data;
   - inspect logs or machine state.
3. Otherwise give Drew exactly one action to perform in the live app.
4. Stop and wait for his observation. Do not send the next instruction in the same message.
5. Record **pass**, **fail**, or **skipped** only from the reported outcome. A screenshot can add context but does not overrule Drew's judgment about layout, motion, color, focus, or timing.

When a check has phases, each phase is a separate turn. For example: create an unstaged edit, wait; stage it, wait; reset it, wait.

## Handle failures

Stop the runbook at the first failure. Capture:

- the action just taken;
- the observed result;
- the expected result;
- relevant live state.

Investigate the root cause before another surface patch. Do not quietly alter the expected result or continue down the checklist. If Drew authorizes a fix, implement and verify it, then repeat the failed check from a clean fixture before resuming.

An unexpected result during teardown is still a product failure. Do not dismiss it as cleanup merely because the primary behavior already passed.

## Fixtures and safety

- Prefer disposable fixtures under a temporary directory.
- Resolve exact paths and Git targets before changing them.
- Make the smallest observable mutation.
- Never modify unrelated user work to manufacture a check.
- Explain any destructive or external action and obtain the approval the environment requires.
- Restore edited fixtures, remove disposable worktrees or branches, and verify cleanup.
- If cleanup itself is the behavior under test, ask for the observation before removing the remaining evidence.

Do not invoke `drive-dev-app` from this workflow. That skill is a separate, explicitly requested debugging tool for synthesized input and unattended machine-checkable outcomes.

## Finish

Report:

- each check and its pass/fail/skipped result;
- any bugs found and how they were resolved;
- automated coverage that replaced manual checks;
- anything still unverified;
- fixture cleanup status.

Do not claim the runbook complete while a check is unanswered, a failure is unresolved, or a fixture remains.
