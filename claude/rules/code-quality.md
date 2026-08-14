# Code Quality

Principles, not conventions. Language and framework specifics (naming cases,
type system rules, lint configuration, test runners) belong in the project's
own code quality doc.

## Anti-defaults (counter common Claude tendencies)

- No premature abstractions. Three similar lines beats a helper used once.
  Tests are the exception: extract at the second copy, not the third.
- Don't add features or improvements beyond what was asked.
- Don't refactor adjacent code while fixing a bug.
- No dead code or commented-out blocks. Unreachable code is dead. A branch you
  haven't needed yet is not.

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

## No defer markers

- Never leave `TODO`, `FIXME`, `HACK`, `XXX`, `TEMP`, or `REMOVEME` in code. A
  marker is a sign the thing should be fixed, so fix it now.
- Never suppress a linter or type checker to silence a violation. The violation
  is the signal to fix the code, not to annotate around it.
- Don't split "make the change" from "fix what it surfaced". Resolve surfaced
  issues in the same change.
- Genuinely out-of-scope future work belongs in a tracker, never as a comment
  in the code.

## Failure modes

- A check that can fail must fail loudly. A silent pass is worse than no check,
  because it reads as coverage.
- Never discard an error stream to keep output clean. Route it where a person
  will see it.

## Testing

- Test through the real interface, not internal state. A test that only asserts
  internal bookkeeping can stay green while the thing it produces is broken.
  Drive the actual control, endpoint, or output a user hits. State-only tests
  give false confidence where it costs the most to be wrong.
- Extract a test helper the second time it is wanted, not the third. Copying it
  once is how three copies happen, and by then they have drifted into three
  subtly different fixtures that each carry their own bug. Share the setup every
  caller needs; leave the parts one package alone wants where they are.
