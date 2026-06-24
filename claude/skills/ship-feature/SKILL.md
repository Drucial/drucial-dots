---
name: ship-feature
description: Run my feature-complete PR process — full local check, open a draft PR, gather Copilot + /code-review findings, triage them (fix / mitigate / ignore, no tech debt), then update the tracking ticket to In Review and mark the PR ready for review. Invoke when a feature build is complete and ready to ship.
---

# Ship a completed feature

Drive my feature-complete PR process end to end. Work through the steps in order; do not skip ahead, and report results at each gate rather than silently continuing.

Adapt the project-specific commands (check command, ticket tracker, review skill) to whatever repo this runs in. The defaults below assume a repo with a `check` script, GitHub Copilot reviews, a `/code-review` skill, and Linear tickets — substitute the local equivalents if they differ.

## 1. Full local check

Run the repo's full check (e.g. `pnpm check` — format + lint + typecheck + tests/coverage).

- If anything fails, fix it and re-run until green. Catch issues locally so they don't burn a CI run.
- Do not open the PR until the check is fully green.

## 2. Open the PR as a draft

- Confirm the branch is pushed.
- Open the PR **as a draft**, so review happens before a full CI run is spent (especially where CI is gated to skip drafts).
- Title and body reference every tracking ticket the PR closes, so the tracker auto-links them.

## 3. Request a Copilot review

Request a GitHub Copilot review on the PR.

## 4. Run /code-review

Invoke the `/code-review` skill against the branch diff. Capture its findings.

## 5. Pull down Copilot's comments

Once Copilot has finished (it runs async — give it a moment, re-check if not yet posted), fetch its review comments from the PR.

## 6. Review the combined findings

Merge Copilot's comments and `/code-review`'s findings into a single list. De-duplicate where both flag the same thing.

## 7. Triage each finding

For every finding, recommend one of: **fix**, **mitigate**, or **ignore** — each with an explicit one-line reason.

- **Default to fixing.** Do not leave tech debt.
- **Mitigate** only when a full fix is out of scope for this PR — capture the residual as a tracked follow-up, never a silent gap.
- **Ignore** only when the finding is wrong or genuinely not worth it — say why.

Present the triage table to me and apply the agreed fixes. Re-run the check after fixes.

## 8. Close out

- **Tracking ticket (if one exists):** update it with any scope changes uncovered during the build, and move it to **In Review**. If no ticket exists, note that and skip.
- **Mark the PR ready for review.** Where CI is gated on `ready_for_review`, this is what fires CI — so it runs once against the reviewed, triaged branch instead of on every intermediate push.

Report the final state: PR link, CI status, ticket status, and the triage summary.
