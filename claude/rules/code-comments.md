# Code Comments

The voice rules in CLAUDE.md apply here too. Applies to new comments, and to any
comment you touch. Purging old ones is fair game as they are found and related.
Favor extreme concision over grammatical correctness.

## When to write comments

**Default to not writing a code comment at all.**
Only reach for a comment when the code cannot express intent or reasoning.
In that case consider whether the code needs a better implementation
or refactor.

- Inline comments stay short.
- Two lines MAXIMUM. This is not a suggestion.
- Count lines as written, and keep each inside the file's usual width. One
  300-character line is not one line, it is the cap dodged.
- Doc comments get four, and no more. They are not an exception to concision,
  they are a longer sentence about a contract.
- Nothing earns an exception. Not a load-bearing workaround, not a subtle
  invariant, not a file header. A header is a doc comment, capped at four like
  any other. The cap is the whole rule.
- If a long comment is needed, it indicates that the code quality is likely bad
  or the implementation is misguided. Fix the code, not the comment.
- A comment at the cap is at the cap, not a target. Most want one line.

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
- Split one comment across a blank line to get two runs under the cap. Nothing
  but air between them means it is one comment, and the cap counts it as one.

### Files, APIs, and contracts

Inline brevity governs documentation too.

- A public function, type, endpoint, or module gets a doc comment: what it
  returns, what it raises, what it mutates, what the caller has to guarantee.
- Document the contract, not the implementation. The promise to the caller is
  the part a reader can't recover from the body.
- Follow the language's format (TSDoc, rustdoc, docstrings, YARD). The project's
  own doc names which one and where it's required.
- A file or module header earns its place when the file's role isn't obvious
  from its name and exports. Say what lives here and what doesn't.
- No ceremonial docblocks. A private one-liner with an honest name needs none.
