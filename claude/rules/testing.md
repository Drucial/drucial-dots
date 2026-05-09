---
alwaysApply: true
---

# Testing

- **Runner:** Vitest + React Testing Library.
- **Location:** co-located `__tests__/` next to source.
- **Naming:** `*.test.ts` / `*.test.tsx`.
- Verify behavior, not implementation. Don't assert on mock call counts.
- One assertion concept per test (multiple `expect()` lines OK if testing one thing).
- Fix or delete flaky tests immediately.
- Run the specific test file you're working on, not the whole suite, until you're confirming integration.
- Prefer real implementations over mocks for internal collaborators (DB, services). Mock only at external boundaries.
