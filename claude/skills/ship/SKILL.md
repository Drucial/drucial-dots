---
name: ship
description: Pre-ship verification + commit + push + PR. Runs typecheck and lint on changed files first; blocks if either fails. Each step requires user confirmation.
argument-hint: "[optional commit message or PR title]"
disable-model-invocation: true
allowed-tools:
  - Bash(git status)
  - Bash(git diff *)
  - Bash(git log *)
  - Bash(git add *)
  - Bash(git commit *)
  - Bash(git push *)
  - Bash(git checkout *)
  - Bash(git branch *)
  - Bash(gh pr create *)
  - Bash(gh pr view *)
  - Bash(pnpm typecheck)
  - Bash(pnpm lint *)
  - Bash(pnpm typecheck *)
---

Ship the current changes through verification → commit → push → PR. Confirm with the user before each mutating step using the AskUserQuestion tool.

## Step 0: Pre-ship verification

Before scanning changes, run typecheck and lint on changed files:

1. Identify changed files: `git diff --name-only HEAD` plus `git diff --name-only --cached`.
2. Filter for TS/JS: only `*.ts`, `*.tsx`, `*.js`, `*.jsx`.
3. Run typecheck: `pnpm typecheck` (project-wide is fine; incremental TS doesn't filter cleanly).
4. Run lint on changed files: `pnpm lint -- $(git diff --name-only HEAD --diff-filter=ACM | grep -E '\.(ts|tsx|js|jsx)$' | tr '\n' ' ')` (skip if no matching files).
5. If either fails:
   - Show the user the failures with file:line excerpts.
   - AskUserQuestion: fix now / commit anyway / abort.
   - Default = fix now. Don't proceed until clean.

This is the deterministic version of the Pre-PR Checklist in CLAUDE.md.

## Step 1: Scan

- Run `git status` to see all changed, staged, and untracked files.
- Run `git diff` (and `git diff --cached`) to see what changed.
- Run `git log --oneline -5` to see recent commit style.
- Present a clear summary: files modified / added / deleted / untracked.
- If there are no changes, tell the user and stop.

## Step 2: Stage & Commit

- Propose which files to stage. **Never stage** these:
  - Secrets: `.env*`, `*.pem`, `*.key`, `credentials.json`
  - Lock files unless intentionally updated
  - Generated: `*.gen.*`, `*.generated.*`, `*.min.*`
  - Build output: `dist/`, `build/`, `.next/`, `__pycache__/`
  - Dependencies: `node_modules/`, `vendor/`, `.venv/`
  - OS/editor: `.DS_Store`, `Thumbs.db`, `*.swp`, `.idea/`, `.vscode/settings.json`
- Draft a commit message based on the changes, matching the repo's existing commit style.
- ASK user to confirm or edit the staged files and proposed commit message.
- Only after confirmation: stage and create the commit.
- If commit fails (pre-commit hook), fix and create a NEW commit (never `--amend`).

## Step 3: Push

- Check if the current branch has an upstream remote.
- If not, propose `git push -u origin <branch>`.
- ASK user to confirm before pushing.
- Only after confirmation: push to remote.

## Step 4: Pull Request

- Check if a PR already exists (`gh pr view`); if so, show URL and stop.
- Analyze ALL commits on this branch vs the base branch (not just the latest).
- Draft PR title (under 72 chars) and body with:
  - Summary: 2-4 bullets.
  - Test plan: how to verify.
- ASK user to confirm or edit.
- Only after confirmation: create the PR.
- Show the PR URL when done.

## Rules

- NEVER skip a confirmation step. Each mutating step requires explicit user approval.
- NEVER force-push.
- NEVER commit `.env`, secrets, or credential files.
- If the user says "skip" at any step, skip and move to the next.
- If $ARGUMENTS is provided, use it as the commit message / PR title.
