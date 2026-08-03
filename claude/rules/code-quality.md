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

Applies to new comments. Don't retrofit old repos. Same voice rules as any
other writing: no em-dashes, no strong adverbs.

- WHY only, never WHAT. If a comment explains what the next line does, delete
  it or rename the thing.
- Comment the code, not the work. No session narration, no review-speak, no
  documenting missteps or superseded approaches. If it only makes sense next
  to the PR, it doesn't belong in the file.
- Terse and infrequent. Digestible code gets no comment. The target register:
  `// else a newer toggle of this edge owns the layout`.
- Two or three lines is the ceiling. Needing a paragraph is a signal, not a
  style problem: the code is unclear, or the rationale belongs in a doc or a
  ticket. Fix the code or move the prose.
- A deviation from the standard path earns one: state the constraint and the
  cost of breaking it, then stop. Concurrency guards, external contracts
  invisible at the call site, and safety justifications qualify. Design
  rationale essays and caps-lock emphasis don't.
- Ticket references only when the ticket holds context the comment can't carry
  (a repro, a measurement). Never as decoration.

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
