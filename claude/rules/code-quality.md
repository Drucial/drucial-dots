# Code Quality

Principles, not conventions. Language and framework specifics (naming cases,
type system rules, lint configuration, test runners) belong in the project's
own code quality doc.

## Anti-defaults (counter common Claude tendencies)

- No premature abstractions. Three similar lines beats a helper used once.
- Don't add features or improvements beyond what was asked.
- Don't refactor adjacent code while fixing a bug.
- No dead code or commented-out blocks.

## Reuse before build

- Search for an existing component, helper, or validation before writing a new
  one. Grep for what the thing does, not for what you would have named it, and
  check shared directories before feature directories.
- If it exists, compose with it. Pass options or parameters instead of
  restyling or reimplementing.
- If it doesn't, confirm with the user before adding a new shared primitive.

## Naming

- Follow the project's existing convention. Consistency with the surrounding
  code beats any rule stated here.
- Booleans read as predicates.
- Functions lead with a verb.
- A name that needs a comment to explain it is the wrong name.

## Comments

The voice rules in CLAUDE.md apply here too. Applies to new comments, and to any
comment you touch. Purging old ones is fair game when asked.

Write a comment when it carries what the code cannot: why a decision was made, a
constraint, surprising behavior, a safety requirement, a failure condition, or
the behavior of a public API. Improve the name and the structure first, and
prefer a test, a type, an assertion, or a link when one of those can communicate
or enforce the same idea. Keep what survives concise, precise, and next to the
code it describes.

Inline comments stay short, two or three lines. Doc comments run as long as the
contract needs, no longer.

Do:

- Explain intent, trade-offs, constraints, and workarounds.
- Document public APIs: assumptions, errors, side effects, safety requirements.
- Comment complex algorithms, regular expressions, and surprising behavior.
- Link what a reader can actually open: an upstream issue, a spec, a standard.
- Write the comment that prevents the next likely mistake.

Don't:

- Restate what clear code already says. The target register for an inline note:
  `// else a newer toggle of this edge owns the layout`.
- Prop up an unclear name or a tangled function. Fix the name or the function.
- Park disabled or obsolete code in a comment. Git has it.
- Write anything vague, speculative, or purely historical. "This used to be X"
  is git's job.
- Comment the work instead of the code. No session narration, no review-speak,
  no documenting missteps.
- Reference a ticket. A private tracker is not something a reader can open, and
  the number rots the next time the tracker is re-keyed. Put the reason in the
  sentence.
- Let a comment drift from the implementation. One that contradicts the code is
  worse than none. Update or delete it in the same change.

### Files, APIs, and contracts

Inline brevity doesn't govern documentation. Different job, different rules.

- A public function, type, endpoint, or module gets a doc comment: what it
  returns, what it raises, what it mutates, what the caller has to guarantee.
- Document the contract, not the implementation. The promise to the caller is
  the part a reader can't recover from the body.
- Follow the language's format (TSDoc, rustdoc, docstrings, YARD). The project's
  own doc names which one and where it's required.
- A file or module header earns its place when the file's role isn't obvious
  from its name and exports. Say what lives here and what doesn't.
- No ceremonial docblocks. A private one-liner with an honest name needs none.

## No defer markers

- Never leave `TODO`, `FIXME`, `HACK`, `XXX`, `TEMP`, or `REMOVEME` in code. A
  marker is a sign the thing should be fixed, so fix it now.
- Never suppress a linter or type checker to silence a violation. The violation
  is the signal to fix the code, not to annotate around it.
- Don't split "make the change" from "fix what it surfaced". Resolve surfaced
  issues in the same change.
- Genuinely out-of-scope future work belongs in a tracker, never as a comment
  in the code.

## Testing

- Test through the real interface, not internal state. A test that only asserts
  internal bookkeeping can stay green while the thing it produces is broken.
  Drive the actual control, endpoint, or output a user hits. State-only tests
  give false confidence where it costs the most to be wrong.
