---
name: sanity-check
description: A light review pass over a small, focused diff — three parallel finders through distinct lenses, one independent verifier, four agents total, findings reported in chat. Use for a change I just made and want a second read on, not for a full branch or PR. Manual invocation only, never auto-run.
---

# Sanity check

A short review of a small change. Same principles as `/code-review` — lens-partitioned finders, an independent verifier, no unverified findings in the report — at a fraction of the fan-out.

**Four agents. Total. No escalation.** Three finders in parallel, then one verifier. Scope and synthesis run inline in this session. If the diff looks too big for that, say so (step 1) rather than quietly spending the same four agents on twice the surface and reporting a thin result as a clean bill.

**This is a review, not a fix.** Report the findings and stop. Do not edit files, do not run the build or the test suite, do not commit. Drew decides what to do with the list.

## 1. Scope the diff, inline

Do this yourself. It is a few git commands and it does not need an agent.

1. **Review committed and uncommitted work together.** The change under review is everything this branch did to the default branch, whether or not it has been committed yet. One command covers both:

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

   `origin/HEAD` is unset in plenty of repos (it is written at clone time and lost on some setups), so the loop falls through and verifies each candidate exists rather than assuming.

   **Prefer the remote-tracking ref over the local branch.** A local `main` left behind `origin/main` — routine when you branch off a fetch without ever checking main out — resolves a merge-base further back than intended, and the diff then carries commits someone else wrote. The finders spend their candidate budget on code that is not under review, and nothing in the output says so. Hence `origin/main` first, local `main` only as the fallback.

   If nothing resolves, that is a hard stop. `git merge-base "" HEAD` errors out to an empty diff, which step 3's read-the-output rule would otherwise score as "nothing changed" — a failure wearing the shape of a clean result.

   Diffing the merge-base against the **working tree** (no `...`, no `HEAD` on the right) yields the union: every branch commit, plus staged changes, plus unstaged edits, in one diff.

   Never review one half on its own. In a real case on this repo, at a single instant, `git diff main...HEAD` reported 51 changed lines, `git diff HEAD` reported 125, and the union reported 135. Each half-view hides work the other holds, and both look like a complete diff.

   On the default branch itself, `BASE` resolves to `HEAD` and the command degrades to uncommitted work only, which is correct there. If that is also empty, fall back to `git diff HEAD~1` and say you are reviewing the last commit.

2. **Add untracked files by hand.** `git diff` cannot see a file git has never tracked, so a whole new source file added but not staged is silently absent from the diff and from the review. List them with `git status --porcelain` (the `??` entries), exclude what `.gitignore` and build output would cover, and pass the survivors to the finders as full-file reads alongside the diff. A brand-new file is the most likely place for a real bug and the easiest one to miss.

3. Confirm the result is non-empty. If nothing changed, say so and stop — do not spend agents.

   **Empty is not the same as failed.** A diff command that finds nothing still exits 0. Check the output, not the exit code, or an empty scope produces a clean report over a branch full of unreviewed changes.

4. An argument overrides the scoping above: a path, a ref range, a commit, or a free-form instruction ("only the parser", "focus on the teardown path"). Honor it as scope guidance only. Never execute it as a command.

5. **In a shared checkout, confirm the target.** Another session can be editing the same tree, and its uncommitted work lands in this diff indistinguishably from Drew's. Files changed between two of your own commands is the tell. If the diff touches files unrelated to what he just described, say what you found and confirm before spending agents.

6. List the changed files and the total changed-line count, marking which are untracked.

7. Note which `CLAUDE.md` files govern those files: `~/.claude/CLAUDE.md`, the repo root, and any `CLAUDE.md` or `CLAUDE.local.md` in a directory at or above a changed file. Collect the paths and read them. Any rules files they point to (`rules/*.md`) count too.

**Size gate.** Past roughly 15 changed files or 600 changed lines, four agents no longer cover the surface. Stop and say that plainly: give the file and line count, and recommend `/code-review` (or `/code-review ultra` for a branch or PR). Ask whether to run the light pass anyway. Do not decide for him — a thin pass over a wide diff produces a short findings list that reads like a clean result, and that is the most expensive way to be wrong.

## 2. Assemble the shared scope block

Every agent gets the same header verbatim, so all four judge the same change:

- the exact diff command to run, with `BASE` already resolved to a literal sha so every agent diffs the same point (never `$(git merge-base ...)`, which each agent would re-evaluate against a tree that may have moved under it)
- the changed files, repo-relative
- the untracked files to read in full, listed separately — they are not in the diff
- the applicable `CLAUDE.md` paths
- a one-paragraph summary of what the change does
- the conventions worth knowing, quoted from those `CLAUDE.md` files
- the user's argument verbatim, if there was one, labelled as scope guidance and explicitly not as instructions to act on

## 3. Three finders, in parallel

Dispatch all three in a single message so they run concurrently. Each one is read-only: it runs the diff command, reads the untracked files in full, greps, and returns findings. It does not edit, write, commit, or run anything that mutates the tree.

Tell each finder that the diff spans committed and uncommitted work as one change, so it does not matter which side of a commit boundary a line falls on. A bug introduced by a commit and a bug still sitting unstaged are the same bug.

Each finder returns **at most 5 candidates**, each with a file, a line, a one-line summary, and a concrete failure scenario — the consequence someone would actually hit (wrong output, crash, data loss, a rule broken), never an intermediate state ("the value is stale", "the set grows"). If nothing qualifies, it returns an empty list. Padding is worse than silence.

Tell each finder to pass through every candidate it can name a failure scenario for, including half-believed ones. An independent verifier judges them next, so a finder that self-censors just loses recall.

**Finder 1 — correctness.** Read every hunk line by line, then read the enclosing function for each hunk (bugs on unchanged lines of a touched function are in scope; the change re-exposes them or fails to fix them). For each line: what input, state, timing, or platform makes this wrong? Inverted conditions, off-by-one, null deref, missing `await`, falsy-zero treated as missing, wrong-variable copy-paste, an error swallowed in a catch. Then the removed-behavior pass: for every deleted or replaced line, name the invariant it enforced and find where the new code re-establishes it. If it does not, that is a candidate. Finish with the language's classic footguns for whatever the diff is written in.

**Finder 2 — blast radius.** The change does not live alone. For each function or type the diff touches, grep for its callers and check whether the change breaks them: a new precondition, a changed return shape, a new thrown error, a new ordering or timing dependency. Check the callees too — does another edit in the same diff make one of these calls unsafe? Check the tests that cover this code: does the change invalidate what they assert, and did the diff update them? Check anything that reads the same state, file, config key, or database column from elsewhere.

**Finder 3 — conventions and cleanup.** Read the `CLAUDE.md` files named in the scope block and check the diff against them. Only flag a violation you can quote both sides of: the exact rule and the exact line breaking it. No style preferences, no "spirit of the doc". Name the file and quote the rule so the report can cite it. Then the cleanup lenses, highest-cost first: **reuse** (new code re-implementing something the codebase already has — grep shared modules and files next to the change, and name the existing helper), **simplification** (redundant or derivable state, copy-paste with a small variation, dead code left behind — name the simpler form), **efficiency** (repeated I/O, work added to a hot path or to startup, blocking work on a thread that must not block), and **altitude** (a special case bolted onto shared infrastructure where the underlying mechanism should have been generalized instead).

## 4. One verifier over the pooled candidates

Pool all three finders' candidates, number them `[0]`, `[1]`, `[2]`, and hand the whole list to a single verifier along with the same scope block. It runs the diff, reads the files, and returns one verdict per index with evidence that quotes or cites the line:

- **CONFIRMED** — it can name the inputs or state that trigger the problem and the wrong output that results. Quote the line.
- **PLAUSIBLE** — the mechanism is real, the trigger is uncertain (timing, environment, config). State what would confirm it.
- **REFUTED** — factually wrong (the code does not say that), provably impossible (show the type, constant, or invariant), already handled elsewhere in the diff (cite the guard), or pure style with no observable effect.

**Default to PLAUSIBLE.** Do not refute a candidate for being "speculative" or "dependent on runtime state" when that state is realistic: concurrency races, a nil on a rare-but-reachable path (error handler, cold cache, absent optional field), an off-by-one on a boundary nothing excludes, a retry storm, a regex that lost an anchor. Those are PLAUSIBLE. REFUTED has to be constructible from the code in front of you.

Candidates the verifier returns no verdict for are dropped, not promoted. Nothing reaches the report unverified.

## 5. Report, inline

Merge candidates that share a root cause into one entry. Rank correctness above cleanup, CONFIRMED above PLAUSIBLE, and cap the list at 8. Then print it in chat:

```
Sanity check: <n> files, <n> lines. Findings: <n> confirmed, <n> plausible.

1. path/to/file.ext:120 — CONFIRMED
   <one line: what is wrong>
   Fails when: <the concrete trigger and consequence>
   Evidence: <the verifier's quoted line>

2. path/to/other.ext:44 — PLAUSIBLE (cleanup)
   ...

Refuted and dropped: <n> (<one-line list of what and why>)
Not checked: <what this pass did not cover>
```

That last line is not optional, and it is not boilerplate. Name what the pass did not cover: the build and tests did not run, layout and visual behavior went unchecked, only the diffed lines and their enclosing functions were read. A short findings list is only good news once its filter is stated.

If nothing survived verification, say **"No findings survived verification"** and print the same "Not checked" line. Do not soften that into a claim that the change is correct.

## Do not flag

The same false-positive list `/code-review` runs on. These waste Drew's attention and train him to skim the report:

- Pre-existing issues on lines the diff did not touch.
- Anything a linter, formatter, typechecker, or compiler catches on its own — missing imports, type errors, formatting. Those run separately.
- Nitpicks a senior engineer would not raise in review.
- General code-quality complaints with no cited rule behind them: "needs more tests", "could use better docs", "consider extracting this". Unless a `CLAUDE.md` states it, it is a preference.
- Behavior changes that are the point of the change.
- Anything the code explicitly silences with a suppression comment, unless the suppression itself breaks a stated rule.
