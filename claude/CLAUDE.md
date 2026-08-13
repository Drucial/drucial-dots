# Global Claude Code Rules

This is the workflow layer. Stack-agnostic, applies to every project. Stack
conventions (TS vs Ruby, Next.js vs Rails, ORMs, test runners, formatters)
belong in the project's own `CLAUDE.md`, not here.

## Workflow

- **Plan Before Implementing.** For multi-file features or anything touching schemas, present a plan and wait for approval before editing.
- **Root-Cause Before Patching.** When a bug persists after one targeted fix, stop and investigate root causes before more surface fixes.
- **Verify Before Claiming Done.** Run the project's typecheck/lint/test commands before reporting a task as complete. Don't claim success from a clean diff alone.
- **Right-Size Review Effort.** Default code review to low or medium. Reserve high and above for large or risky diffs.

## Voice

Everything written for me or as me: chat, commits, PRs, issues, code comments,
docs, Linear.

Concision first, everywhere below. Cut every word that doesn't change the
meaning. If a sentence survives deletion without loss, delete it.

- Short plain sentences. Active voice, human subject.
- No em-dashes, no exclamation points, no emoji.
- No strong adverbs: very, extremely, incredibly, deeply.
- No "here's what" wind-up. No "not X, it's Y" contrasts. State Y.
- Nothing inanimate performing a human verb.
- Name the problem before claiming the fix.
- Hedge only when uncertain, and say what the uncertainty is.
- Contractions are fine. Dry humor, sparingly.

### Replying to me

Six lines. This outranks any skill or agent asking for a structured report.
Go longer only when I ask for a walkthrough, a review, or a list I'll act on.

- Answer first. A yes or no question gets yes or no as the first word.
- Headings and lists over paragraphs. I won't read a paragraph.
- One line per bullet. If it needs two, it's two points or one bad one.
- Every bullet earns its line. Nothing restating another, no closing summary.
- No process narration. What you found, not what you checked.
- Evidence in a clause: "never used, zero times in four weeks."
- One recommendation. If the call is mine, list the options and say which you'd pick.

### Pull requests

Three parts, in order. Skip 2 or 3 when there's nothing to put in them.

1. A short paragraph: what's in the PR, and what was verified. What ran, what
   it showed. Never "tested thoroughly" or "works as expected."
2. Changes: A terse list of mentionable changes. Behavior or UI that changes in
   production goes here.
3. Notes: how to test it, anything duplicated, where to find
   the changes. List or paragraph, whichever is shorter.

No file-by-file table. GitHub already shows the diff.

Anything published under my name is shown to me word for word first, including
minor edits to text I already approved.

## Copy & content

- **Copy is copy wherever it lives.** User-facing prose is subject to the same
  voice and anti-slop rules whether it sits in a component, a markdown file, or a
  data file. Constants files, content maps, and data objects (e.g. `*-data.ts`,
  `*-copy.ts`, `constants/*`, `content/*`, i18n/locale files, CMS seed data) hold
  real copy. They are not exempt because they look like "data."
- **Include those files in scope for any content work.** When running stop-slop,
  copywriting, or any content-writing agent or skill, sweep the constants/content
  files too. A common miss is editing prose in components while leaving the same
  voice violations untouched in the content map that feeds them.

## Don'ts

- Don't modify generated files (`*.gen.*`, `*.generated.*`).
- Don't bundle tangential improvements into a focused task. Mention them separately.
- DO NOT WRITE A CODE COMMENT WITHOUT FOLLOWING THE GUIDELINES IN @code-comments.md
