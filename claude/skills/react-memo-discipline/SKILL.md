---
name: react-memo-discipline
description: Use when writing or reviewing React code that contains useMemo, useCallback, or React.memo — including considering adding one or being asked to "optimize" a component. Trigger symptoms include useMemo over primitives (`useMemo(() => a + b, [a, b])`), useCallback on a function only used in a regular DOM handler, useMemo(() => ({x, y}), [x, y]) where the consumer isn't React.memo'd, "I'll memoize just in case" reasoning, and "looks more performant" justifications. Reflects React's "Should you add useMemo everywhere?" guidance and React Compiler's auto-memoization rationale.
---

# React Memoization Discipline

`useMemo`, `useCallback`, and `React.memo` are precision tools for two narrow jobs: **referential stability** (when a downstream consumer cares about identity) and **caching measurably expensive work**. Without one of those reasons, the wrap usually makes the component slower, hides bugs (stale deps), and adds review noise.

## Default: don't memoize

Plain values, inline functions in JSX, and fresh object literals are fine. New closures per render are cheap — the cost only matters when something downstream cares about identity.

## Memoize for referential stability — only when a consumer needs it

Wrap a value only if **one of these four consumers** exists:

1. **Another hook's deps array** — `useEffect(..., [computed])`, `useMemo(..., [...])`, custom hook with deps
2. **A `React.memo`'d child component** receiving the value as a prop
3. **A context provider's `value`** — fresh objects re-render every consumer
4. **A third-party hook** that documents identity-stable inputs (some form libs, dnd-kit)

No matching consumer → no wrap.

## Memoize expensive computations — only when measured

"Expensive" means **React DevTools profiler shows the work exceeds a frame budget on real input.**

**Qualifies:** sorting/filtering thousands of rows, parsing large JSON, building deep trees, regex compilation, normalizing nested API responses.

**Doesn't qualify:** `a + b`, `value.toFixed(2)`, `formatPhone(x)`, `arr.filter(...)` for arrays under ~100 items, object spreads of small inputs.

## useCallback specifically

- Function → `React.memo`'d child → wrap
- Function → another hook's deps → wrap
- Function → regular `<button onClick={...}>` / `<input onChange={...}>` → **inline, don't wrap**
- Function → `useEffect` cleanup → already a closure, no wrap

## Hidden costs

- Stale dep = stale closure = correctness bug (worse than a perf miss)
- The deps array still runs every render — no free lunch
- Cache slot occupies memory
- Diff/review burden — readers have to verify the deps

## React Compiler — check first

If the project has the React Compiler on, **manual memoization is largely redundant** — the compiler auto-memoizes based on actual reads. Adding manual `useMemo` / `useCallback` on top is overhead with no benefit.

Quick check:

- `grep reactCompiler next.config.*` — Next.js 16.2+ has stable built-in support (`reactCompiler: true`, plus `babel-plugin-react-compiler` v1.0.0 as devDep)
- `grep react-compiler` in babel config / package.json devDeps — direct Babel plugin
- `'use memo'` / `'use no memo'` directives → opt-in mode is enabled

**If on, default to _removing_ manual memos rather than adding more.**

## Rationalization table

| Excuse                             | Reality                                                                                                        |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| "Just in case"                     | No consumer = no value. Delete.                                                                                |
| "Looks more performant"            | The wrap runs every render. For trivial work you've made it slower.                                            |
| "We always memoize handlers"       | Only if the consumer is memo'd.                                                                                |
| "Child might re-render"            | All children re-render when the parent does. Only a problem if (a) `React.memo`'d or (b) measurably expensive. |
| "Passing to a context"             | Real case — memoize the value object.                                                                          |
| "It's a complex computation"       | Quantify with the profiler. "Complex" without numbers is gut feel.                                             |
| "We don't have the React Compiler" | Then apply the four-consumer rule. Don't memoize speculatively.                                                |

## Red flags — STOP

- `useMemo(() => <primitive expression>, [...])` — primitives have no referential identity to preserve
- `useCallback` on every event handler in a component
- `useMemo(() => ({ x, y }), [x, y])` whose consumer is a regular JSX prop on a non-memo'd child
- `React.memo` applied without first measuring that the component re-renders unnecessarily _and_ that the re-renders are expensive
- Memo added "while I'm in here" without an attached profiler finding
- Defensive memoization of a custom hook's return because "callers might use it in deps" — let callers memoize at their call site if they need to

## When called out

Either:

1. Name the consumer that needs the stable reference (one of the four cases above), OR
2. Cite the profiler measurement that justifies the cache, OR
3. Remove it.

"Just in case" isn't an answer.

Sources:

- React useMemo reference — react.dev/reference/react/useMemo (see "Should you add useMemo everywhere?")
- React Compiler — react.dev/learn/react-compiler
