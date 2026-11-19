---
name: ship-feature
description: Take a finished branch through local review to a pull request ready for review, then clean up after the user reports the merge. Use when a feature is complete, when the user asks to ship or open a PR, or when they report that a shipped PR has merged. Never merges.
---

# Ship a completed feature

Read the repo's `CLAUDE.md` or `AGENTS.md` first. It owns the check command, branch naming, PR conventions, and CI expectations. Ask where it is silent and the answer matters.

Work silently between steps. Speak only when a step needs the user or produces an artifact. **Never merge.**

## Steps

1. **Preconditions.** On a feature branch, the scoped work is committed with nothing unrelated in it, tests travel with their behavior, and a diff exists against the default branch. Stop if any fails.

2. **Full check.** Run what CI runs: format, lint, typecheck, tests, build. Resolve the command from the repo's instructions, then its task runner, then its CI workflow.
   - Fix what this change broke and re-run until green.
   - Stop and surface failures this change didn't cause.
   - Stop after a second failed fix on the same failure.

3. **Local review.** If the user supplied review findings, use those. Otherwise run `/code-review` headless from the repo root with the branch checked out, passing the level only if the user gave one:

   ```bash
   NO_WRITES='Edit Write NotebookEdit Bash(git push:*) Bash(git commit:*) Bash(git checkout:*) Bash(git switch:*) Bash(git reset:*) Bash(git restore:*) Bash(git stash:*) Bash(git clean:*) Bash(git rebase:*) Bash(git merge:*) Bash(git fetch:*) Bash(git branch:*) Bash(git worktree:*) Bash(git tag:*) Bash(gh pr comment:*) Bash(gh pr review:*) Bash(gh pr edit:*) Bash(gh pr merge:*) Bash(gh pr ready:*) Bash(gh pr close:*) Bash(gh pr checkout:*)'
   claude -p "/code-review [level] <branch>" --output-format json --permission-mode auto --disallowedTools "$NO_WRITES"
   ```

   - Never pass `--comment`, `--fix`, `--continue`, `--resume` or `--fork-session`, and never trim the denylist.
   - Read `result` and `permission_denials`. A run denied the diff didn't review it. Report that and offer a rerun.
   - Afterwards, confirm the branch and working tree are unchanged.

   Count added lines from `git diff --unified=0 <default>...HEAD` that are comments in their file's language, excluding tooling directives, generated or vendored files, and prose files.

4. **Triage.** Check each finding against the code to confirm whether it's valid, then call it `fix`, `mitigate`, or `ignore` with a reason. Present one table and wait for approval:

   ```text
   | # | Finding | Valid | Call | Reason |
   |---|---------|-------|------|--------|
   ```

   Below it, give the comment-line count, naming the files carrying the most when it isn't zero. With no findings and no added comments, say so in one line and continue to step 6.

5. **Apply.** Apply only the approved calls, committing atomically, and re-run step 2 until green. Stop and re-plan if a fix exposes a larger problem.

6. **Open the PR.** Push with `git push -u origin <branch>` and open the PR ready for review. Use the repo's PR template if it has one, otherwise:

   ```text
   ## Summary

   - <change>

   ## How to test

   - <setup or steps a reviewer needs>

   Closes #<n>
   ```

   - Cover the full breadth of the change, stating only what the PR contains.
   - Include `How to test` only when a reviewer needs specific setup or steps to test it.
   - Link a ticket or issue only when the branch, commits, or repo instructions name one.

   Confirm CI started with `gh pr checks`. Skipped, cancelled, or missing checks aren't passes. If CI didn't start, ask. Never push an empty commit.

7. **PR review.** Wait for CI with `gh pr checks --watch`; review bots usually post within that window. Then gather unresolved feedback:
   - Top-level reviews and comments: `gh pr view --json reviews,comments`.
   - Inline threads: `gh api repos/{owner}/{repo}/pulls/<n>/comments`, skipping resolved and outdated ones.
   - Fix CI failures this change caused as in step 2.

   Triage the feedback as in step 4 and wait for approval, then apply as in step 5 and push. Never reply to or resolve threads unless the user asks. If the push draws new reviews or CI failures, repeat once, then stop and report. With no reviews by the time CI finishes, note it and continue.

8. **Hand back.** Omit empty lines:

   ```text
   **PR** <link>
   **Triage** fixed <n> · mitigated <n> · ignored <n>
   **PR review** fixed <n> · mitigated <n> · ignored <n>
   **Verification** <full check result> · CI <final status>
   ```

   Close with one line saying step 7 re-runs when they say they're about to merge or ask to check reviews, and step 9 runs when they report the merge.

9. **After the merge.** Only on the user's word.
   - Verify with `gh pr view --json state,mergedAt,mergeCommit,headRefName`: `MERGED` with a merge commit. `CLOSED` isn't merged.
   - Check `git worktree list`. A worktree holding the branch is the user's call.
   - Check nothing is left on the branch by comparing content, since a squash rewrites shas. Anything found stops cleanup.
   - Switch to the default branch and pull, delete the local branch with `git branch -d` (never `-D`), delete the remote if it still exists, then `git fetch --prune`.
   - If a ticket or issue is linked, confirm it reached done.
   - Report the PR, cleanup, and anything left alone.
