# Agent briefs

Fill every `{{placeholder}}` before sending. An agent gets exactly one brief and one file set.

## First pass

```text
Comments-only cleanup in {{repo}} (branch {{branch}}, base {{base}}). Other agents are editing other files in this working tree at the same time.

## Your files. Touch nothing else.
{{file list, or directories when the agent owns whole packages}}

## Hard constraints
- Change comments only. No renames, no reformatting beyond the formatter, no fixes. Report bugs instead.
- Never run git add, commit, stash, checkout or reset. Never run the full test suite or build.
- Leave tooling directives alone. The stripper already skips them.
{{doc-referenced comments in these files, each "keep a one-line why on <name>", or omit}}

## The rules. Apply exactly.
{{Comments & Documentation section of the global instructions, verbatim}}

Most comments in a typical repo break these rules and should go. When in doubt, delete.

## Procedure per file
1. Read the original in full: `git show {{base}}:<path>`.
2. Strip it: `{{strip command}} <paths>`. Many files can go in one call.
3. Add back only what the rules allow, rewritten to fit:
   - one file-purpose line where the file name doesn't say it
   - short contract docs on exported names whose signature doesn't already say it
   - one-line whys on declarations
   - nothing inside function bodies
   - nothing in tests except a rare non-obvious why on a test declaration
   A reason that lived inside a body moves to the enclosing declaration as one line, or is dropped.
4. Format: `{{format command}} <paths>`.
5. Verify: `{{same command}} {{repo}} {{base}} <paths>` must print "comments only" for every file. For any other result, restore the file with `git show {{base}}:<path> > <path>` and redo it.

## Report, short
- Comment lines before → after, for your files.
- The checker result.
- Comments that were wrong or stale.
- Bugs or dead code you noticed, not fixed. Quote file:line.
- Removed comments that repo docs point at.
- Facts about external systems (APIs, libraries, platforms) that lived only in deleted comments.
```

## Second pass

```text
Second, stricter comments-only pass in {{repo}} (branch {{branch}}). A first pass already removed most comments; judge what is left. Other agents are editing other files at the same time.

## Your files. Touch nothing else.
{{file list or directories}}

## Hard constraints
- Delete or shorten comments only. Add none. No code changes. Report bugs instead.
- Never run git add, commit, stash, checkout or reset. Never run the full test suite or build.
- Leave tooling directives alone.
{{doc-referenced comments to keep, or omit}}
{{known violations from audit, each file:line and the rule it breaks, or omit}}

## The rules
{{Comments & Documentation section of the global instructions, verbatim}}

## The test for every remaining comment
- Delete a contract doc when the name and signature already say it. Typical: "<Name> returns the <thing>", message types described as "asks the root to <do the obvious>", accessors, constructors.
- Cut a contract doc that mixes in how or why down to what a caller needs. Delete it if nothing caller-facing remains.
- Delete a "why" that describes what the code does, or whose reason can be read from the code or a nearby name.
- In tests, delete any comment whose reason can be read from the code.
- Shorten anything over its limit: a why to one line, a contract doc to three.
- Keep facts about external systems and choices that look like bugs. Example: "POST takes only this form; given 'Copilot' it answers 200 and writes nothing."
- When in doubt, delete.

## Procedure
1. List what remains: `{{audit command}} -list all <dir>` for each of your directories, then read each comment in context.
2. Edit. A blank line left only to separate a deleted comment may go.
3. Format: `{{format command}} <changed paths>`.
4. Verify: `{{same command}} {{repo}} HEAD <changed paths>` must print "comments only" for each.

## Report, short
- Comment lines before → after.
- The checker result.
- Up to 5 borderline keeps, quoted.
- Bugs noticed, if any. Quote file:line.
```
