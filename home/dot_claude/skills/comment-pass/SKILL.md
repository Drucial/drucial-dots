---
name: comment-pass
description: Bring a whole Go, TypeScript/JavaScript or Swift repo's comments in line with the global comment rules, proving no code token changes. Use when the user asks to run a comment pass, strip or clean up comments across a repo, or bring a repo in line with the comment rules. Manual invocation only, since it edits every source file.
---

# Comment pass

This skill owns **one repo's comments, from its current state to the Comments & Documentation rules in the global instructions**, with the code proven untouched at every commit.

One breadcrumb per phase. The only artifacts are the setup summary when a gate stops you, the lost-knowledge brief, and the final report.

## Guarantees

These hold at every commit. A step that would break one stops the run.

- **No code changes.** Every changed file passes `same` against the base ref. Formatter whitespace is the only other change.
- **No directive lost.** `same` fails when a tooling directive disappears.
- **Every source file is in exactly one batch.** Checked before any agent starts.
- **Nothing unverified is committed.** `same`, the formatter check and the linter pass on the files first.
- **Nothing unverified is reported.** An agent's claim about a bug or a stale comment is checked against the code before it reaches the user.

## Language

Detect from the repo root, then read the matching reference before doing anything else:

| Signal | Toolset | Reference |
|---|---|---|
| `go.mod` | Go | [references/go.md](references/go.md) |
| `package.json` with `.ts`, `.tsx`, `.js` or `.jsx` sources | TypeScript | [references/typescript.md](references/typescript.md) |
| `Package.swift`, `*.xcodeproj` or tracked `.swift` sources | Swift | [references/swift.md](references/swift.md) |

A repo with more than one runs each toolset, with separate batches per language. Any other language stops the run: say "comment-pass supports Go, TypeScript/JavaScript and Swift; <language> needs a parser-backed checker first." Never run a pass without `same`.

## 1. Setup

1. **Clean tree.** Uncommitted changes stop the run; name the files.
2. **Branch.** Follow the repo's CLAUDE.md or AGENTS.md rules for branches and tickets, and ask if a ticket is required. Default to `chore/comment-pass`. Record the base ref as the current commit sha.
3. **Tools.** Build or locate them per the language reference, into the session scratchpad.
4. **Rules.** Copy the "Comments & Documentation" section of the global instructions verbatim. It goes into every agent brief. Never paraphrase or summarize it.
5. **Preflight.**
   - Comments the repo's docs point at: `grep -rniE 'carries a comment|commented as such|see the comment' CLAUDE.md AGENTS.md docs .claude 2>/dev/null`. Each keeps a one-line why; pass it to the agent that owns the file.
   - Code that reads comments at runtime or in tests: the language reference's grep. A hit stops the run until the user decides.

## 2. Measure and batch

1. Run `audit -list none` for comment lines per package or directory.
2. Batch at roughly 1.5–2k comment lines per agent. Keep a source file with its tests. Split a package over 2k by file, and group small packages together.
3. Cap at 8 agents; ask before going over.
4. **Coverage gate.** The union of all batches must equal every non-generated source file the tools see. Print `N files in M batches, 0 unassigned` before launching. Anything unassigned is a batching bug, not a skip.

## 3. First pass

Launch one background agent per batch in a single message, using the first-pass brief in [references/agent-brief.md](references/agent-brief.md). Fill every placeholder.

As each agent finishes:

1. `same <repo> <base> <its files>` passes for every file.
2. The formatter check and linter pass on its files, per the language reference.
3. Commit per package: `Strip <package> comments to the comment rules`. A package split across agents gets one commit per agent's file set.

A failing file is restored from the base ref and redone through the brief. Never hand-edit code to make `same` pass.

Wrap file lists in `bash -c '...'`. zsh does not word-split `$FILES`.

## 4. Audit

Run `audit -list violations` on the tree. Required:

- 0 comments inside a function body
- 0 floating comments
- 0 over their length limit
- every package's count lower than at the base

A package whose count did not move was missed; batch it. Violations carry into the second pass as an explicit list.

## 5. Second pass

Run the second-pass brief from [references/agent-brief.md](references/agent-brief.md) over everything, in about 3 batches by volume. Commit per package: `Drop <package> docs that restate their names`. Run `audit` again and require 0 violations.

## 6. Full check

Run the repo's full check from the language reference. It must pass. A failure is investigated, not patched around.

## 7. Recover lost knowledge

The rules delete every comment inside a function body, including the ones recording how an external system behaves.

1. Export the base with `git archive <base> | tar -x -C <scratch>/base`.
2. Run `audit -list in-body -match '<terms>'` on it. Build `<terms>` from the repo's third-party dependency names plus `API|endpoint|HTTP|GraphQL|REST|[45][0-9][0-9]|null|undefined|workaround|quirk|upstream|browser|Safari|iOS|Android`.
3. Drop anything the repo's docs already cover, by grepping each fact's key terms.
4. For each remaining fact, confirm the code still does what the comment described.
5. Propose a short list for the repo's agent docs. On approval, commit it on the branch as a doc-only commit.

## 8. Report

```markdown
**Result:** <before> → <after> comment lines.

**Verification:**
- `same` against <base>: <N> files, 0 failing
- `audit`: 0 violations
- <full check>: <result>

**Commits:** <N> on `<branch>`, not pushed.

**Worth a ticket:**
- <verified claim>, `<file:line>`, <why it matters>

**Dropped:**
- <agent claim that did not verify>, <why>

**Borderline keeps:**
- <up to 5 quoted comments>
```

Never push, open a PR or file a ticket without asking.
