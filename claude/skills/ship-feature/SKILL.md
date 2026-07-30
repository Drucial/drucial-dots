---
name: ship-feature
description: Run my feature-complete PR process — full local check, push, open a draft PR, gather Copilot + /code-review findings, triage them (fix / mitigate / ignore, no tech debt), apply, push again, then mark the PR ready for review. Invoke when a feature build is complete and ready to ship.
---

# Ship a completed feature

Drive my feature-complete PR process end to end. Work through the steps in order; do not skip ahead, and report results at each gate rather than silently continuing.

**This file is the source of truth; the copies in project repos are downstream.** Each repo carries a real copy rather than a symlink, because a cloud session clones that repo on its own — a link into a sibling checkout would dangle there, and the skill would silently not exist in the one place it can't be fixed by hand. So edit this file, then copy it out; never edit a repo's copy directly, or the next sync overwrites it.

The one deliberate exception is **zen-term**, whose flow genuinely differs — SwiftPM commands, a stretch of its life with no remote, and a GUI handover runbook. It keeps its own adaptation and is not overwritten by a sync.

Adapt the project-specific commands (check command, ticket tracker, review skill) to whatever repo this runs in. The defaults below assume a repo with a `check` script, GitHub Copilot reviews, a `/code-review` skill, and Linear tickets — substitute the local equivalents if they differ.

## 1. Full local check

Run the repo's full check (e.g. `pnpm check` — format + lint + typecheck) and its test/coverage gate.

- If anything fails, fix it and re-run until green. Catch issues locally so they don't burn a CI run.
- Do not push until the check is fully green.

## 2. Push the branch

Commit and push (`git push -u origin <branch>`). Use the tracker's generated branch name; don't invent one.

This is its own step deliberately. Buried inside the PR step as "confirm the branch is pushed", it stops reading as a discrete action — and becomes something to chain onto another command. Step 9 is where that chaining has already caused a silent CI failure.

## 3. Open the PR as a draft

- Open the PR **as a draft**, so review happens before a full CI run is spent (especially where CI is gated to skip drafts).
- Title and body reference every tracking ticket the PR closes, so the tracker auto-links them.

## 4. Request a Copilot review

**`gh pr edit --add-reviewer` cannot do this.** It lowercases the login and fails with "Could not resolve user with login 'copilot'", and `copilot-pull-request-reviewer[bot]` is the login Copilot _reviews as_, not a requestable one. Both failures read like Copilot is unavailable; it isn't. Use the GraphQL `requestReviews` mutation with the Bot's node id:

```bash
PR_ID=$(gh api graphql -f query='query { repository(owner:"OWNER",name:"REPO"){ pullRequest(number:NNN){ id } } }' --jq '.data.repository.pullRequest.id')
BOT_ID=$(gh api graphql -f query='query { repository(owner:"OWNER",name:"REPO"){ suggestedActors(capabilities:[CAN_BE_ASSIGNED],first:20){ nodes{ ... on Bot { id login } } } } }' --jq '.data.repository.suggestedActors.nodes[] | select(.login=="copilot-swe-agent") | .id')
gh api graphql -f query='mutation($pr:ID!,$bot:ID!){ requestReviews(input:{pullRequestId:$pr, botIds:[$bot], union:true}){ pullRequest{ reviewRequests(first:10){ nodes{ requestedReviewer{ ... on Bot { login } } } } } } }' -f pr="$PR_ID" -f bot="$BOT_ID"
```

The requestable actor is `copilot-swe-agent`; it comes back as `copilot-pull-request-reviewer` in the confirmation, which is expected. Resolve the id from `suggestedActors` rather than hardcoding it, and if that query returns no Bot, say the request failed rather than that Copilot is unavailable.

**A repo with automatic Copilot review enabled produces a review whether or not the request succeeded**, so a review appearing is not evidence the request worked. Confirm from the mutation's own response.

It runs async; continue and re-check later.

**Never `@copilot`, in a comment or anywhere else.** The mutation above is the only way to request a review. An `@`-mention summons it out of band, and it re-fires on every edit of the comment that carries it. Read its findings from the review comments and write your triage as ordinary prose that does not address it. This holds for every comment on the PR, the description included.

## 5. Run /code-review — I run this, not you

**Stop here and ask me to run it.** `/code-review` is user-triggered and billed; a session cannot invoke it — not via the Skill tool, not via Bash, not via a Workflow. Don't try, and don't treat the failure as a bug to route around.

Say plainly that you're blocked on this and what to run:

- `/code-review` for the working diff
- `/code-review ultra` for a multi-agent cloud review of the branch, or `/code-review ultra <PR#>` for the PR opened in step 3

Then **wait** for the findings before starting step 7. Step 6 is Copilot's, runs on its own clock, and should proceed while you wait — fetch its comments as soon as they land. It is steps 7–10 that block, because the triage in step 8 needs both sources in front of it.

If I decline or say to skip it, continue with Copilot's review as the only source and **say so in the step 7 output**. What you must never do is run your own review pass and present it as `/code-review`'s findings — name which review actually produced each finding.

## 6. Pull down Copilot's comments

Once Copilot has finished, fetch its review comments from the PR. Re-check if they aren't posted yet.

## 7. Review the combined findings

Merge Copilot's comments and `/code-review`'s findings into a single list. De-duplicate where both flag the same thing.

## 8. Triage each finding

For every finding, recommend one of: **fix**, **mitigate**, or **ignore** — each with an explicit one-line reason.

- **Default to fixing.** Do not leave tech debt.
- **Mitigate** only when a full fix is out of scope for this PR — capture the residual as a tracked follow-up, never a silent gap.
- **Ignore** only when the finding is wrong or genuinely not worth it — say why.

Present the triage table to me, apply the agreed fixes, and re-run step 1 until green.

## 9. Push the fixes, then mark ready — as two separate actions

**Push, let the push register, and only then mark the PR ready. Never chain them** (`git push && gh pr ready`).

Both emit a webhook — `synchronize` and `ready_for_review`. Fired in the same instant they land in the same CI concurrency group, so one cancels the other, and the survivor is often the `synchronize` run, whose payload still says `draft: true` and therefore skips every job. The PR then shows skipped checks, which look like passes at a glance, with no CI having run at all. It is a failure that reports success.

Keying the concurrency group on `github.event.action` fixes it repo-side, but don't assume that's configured — separate the two actions regardless.

After marking ready, **confirm CI actually started** (`gh pr checks` or the run list). "Skipping" is not "passing". If nothing ran, close and reopen the PR to fire a clean `reopened` event rather than pushing an empty commit.

## 10. Close out

- **Let the tracker move the ticket.** Where the tracker has a PR integration (Linear does, via the ticket id in the branch/PR), marking the PR ready moves it to **In Review** on its own. Don't write that status by hand — a manual move is a second copy of a transition the integration owns, and it drifts the moment the automation changes.
- **Move it yourself only when nothing else will:** no PR (a local-only ship), or a tracker with no PR integration. Note which case applies.
- **Tracking ticket:** update it with any scope changes uncovered during the build. If no ticket exists, note that and skip.
- **Never merge.** Shipping ends at "ready for review"; merge only on an explicit instruction to merge.

Report the final state: PR link, CI status (from an actual check, not an assumption), ticket status, and the triage summary. Say plainly what was verified and what wasn't — a green CI is not a substitute for anything that needed eyes on a screen.

If the change has manual checks, invoke the global `interactive-runbook` skill and work through them with me one at a time before declaring the shipping run complete. Do not substitute an unattended driver or print the whole checklist and leave it as a handoff.
