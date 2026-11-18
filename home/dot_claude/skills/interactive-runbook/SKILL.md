---
name: interactive-runbook
description: Walk the user through a runbook one check at a time, recording pass, fail, or skip from what they report and resolving a failure before resuming. Use when the user asks to run or walk through a runbook, or when behavior needs a person observing a live build. Derives the runbook through the runbook skill when none exists.
---

# Interactive Runbook

The user runs the app and reports what they see. This skill sequences the checks, records results, and resolves failures. It sets up fixtures and applies approved fixes. It never starts the app.

## 1. Build the queue

1. Use the runbook in the conversation. If there is none, invoke `runbook` and take its output as written.
2. Preserve each check and its expectation. A check you don't understand is a question for the user.
3. A runbook from anywhere else may need normalizing: drop checks for functionality, merge checks on the same surface, and lead with the surface most likely to look wrong. Say what you changed.
4. Number the queue before check 1 and never renumber it.
5. State the count, preconditions, run command, and anything to prepare. Ask the user to start the build.
6. Keep the queue and results in conversation state, never on disk.

## 2. Present one check

One check per message, then stop and wait:

```text
## Check <n> of <m>

## Instructions

- <one action>

## Expectation

- <observable result>

**Pass, fail, or skip?**
```

- Instructions are actions, one per bullet: `Press ⌘⇧P`, not "you'll want to open the command palette".
- Backtick every chord, key, selector, and path.
- Expectations are things the user can see from where they sit.
- Nothing above the heading or below the question, except one line for setup when the check needs a controlled starting state (a fixture, test data, a disposable branch). The user still reports the result.

## 3. Read the result

Record results only from what the user reports, never from tests, code, or silence. A screenshot adds context but doesn't overrule their judgment.

- **Pass:** record it and present the next check.
- **Skip:** record it, with a reason if they give one. It stays unverified in the final report.
- **Fail:** if they didn't say what they saw, ask and stop.

## 4. Resolve a fail

The queue halts at the failed check. Decide which kind it is, and ask if it's unclear:

- **Bug:** the behavior is broken. Investigate, find the root cause, present a fix plan, and wait for approval. Never patch the symptom.
- **Design change:** it works as built, but the user wants it different. Propose the change and wait for approval.

If a second fix for the same check fails, stop editing and dispatch `bug-triage` with the check, expected and observed behavior, the diff, the attempted fixes, and the evidence. Withhold your hypothesis. Verify its findings before forming a new plan.

If the user defers the fix, record **failed, deferred** and resume.

## 5. Fix and re-run

Implement the approved change, run the relevant automated checks, and commit. Report one line per fix: cause or request → change, and the commit.

If the fix reaches other surfaces, add checks for them as `<n>a`, `<n>b` after the failed check.

A fix doesn't pass a check. Restore the starting state and present the failed check again for a fresh result. Then run any added checks and resume the queue.

## 6. Fixtures

- Prefer disposable fixtures in a temp directory. Resolve exact paths and git targets before changing them.
- Restore each fixture once its checks finish, remove disposable branches and worktrees, and verify the cleanup.
- When cleanup is the behavior under test, get the user's observation first.

## 7. Finish

The run is complete when every check has passed, been skipped, or been deferred, and every fixture is clean.

```text
## Runbook Complete

**Passed:** <n>   **Skipped:** <n>   **Failed, deferred:** <n>

**Fixes**
- <cause or request → change, commit>

**Unverified**
- Check <n>: <skipped or deferred, and why if known>
```

Omit empty sections.
