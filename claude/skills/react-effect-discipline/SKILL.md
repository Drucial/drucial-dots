---
name: react-effect-discipline
description: Use when writing or reviewing React code that contains useEffect, or considering one for state-from-prop sync, derived values, ref mirrors, or cleanup-as-side-channel patterns reacting to user dismissal. Trigger symptoms include `useEffect(() => setX(prop), [prop])`, cleanup that fires invalidate()/finalize() on unmount to react to a popover/modal closing, mirroring a ref alongside state because "the closure is stale", and any "I'll invalidate on unmount" reasoning. Based on react.dev/learn/you-might-not-need-an-effect.
---

# React Effect Discipline

`useEffect` is the wrong tool more often than it's the right one. Per the React docs' "You Might Not Need an Effect," **legitimate effects synchronize with an _external_ system** (DOM, browser API, non-React store, timer). Anything else has a more direct primitive.

## Reject by default

### State-from-prop sync — derive at render

```tsx
// ❌ writes prop into state via an effect
useEffect(() => {
  if (prop !== current) setCurrent(prop);
}, [prop]);

// ✅ store the user's *intent*; derive the *displayed* value
const display = condition ? prop : stored;
```

If the prop should _reset_ state, use `key={prop}` on the component.

### Cleanup-as-side-channel for user dismissal — wire to the event

```tsx
// ❌ react to "user dismissed the popover" via unmount cleanup
const flagRef = useRef(false);
useEffect(
  () => () => {
    if (flagRef.current) invalidate();
  },
  [],
);

// ✅ controlled `open` gives the dismiss event directly
<Popover
  open={open}
  onOpenChange={(next) => {
    if (!next && needsFinalize) finalize();
    setOpen(next);
  }}
/>;
```

The component unmounting is a _consequence_ of the user dismissing — not the event itself. Use the handler that fires for the _cause_, not the cleanup that fires for the effect.

### Other anti-patterns from the doc

- Computing values for rendering → `useMemo`, or compute inline.
- Resetting state when props change → `key` prop.
- Chaining `setState` inside an effect → derive both from one source.
- Subscribing to a Store → `useSyncExternalStore`.
- Sharing logic between handlers → extract a helper.

## Legitimate effects

External-system synchronization IS the supported use case per the docs:

- Mount-time `window.location.hash` / `localStorage` read in a `"use client"` SSR'd component (those are browser-only).
- `addEventListener` + `removeEventListener` cleanup.
- `setInterval` / `setTimeout` + cleanup.
- Subscribing to a non-React store when `useSyncExternalStore` isn't a fit.
- Direct DOM measurement when no render-time API exists.

When challenged on a legitimate effect, **defend it explicitly** with the "synchronizing with external systems" framing and offer the alternative trade-off (e.g. `useState` lazy initializer with hydration mismatch). Don't reflexively delete it.

## Before typing `useEffect`, ask

1. Is the real signal an `onX` callback I'm not wiring? → use the callback.
2. Am I storing something I could derive at render? → derive.
3. Am I mirroring a prop into state? → derive, or `key` to reset.
4. Am I reacting to "user did X" via unmount? → wire to `onX` directly.
5. Am I synchronizing with an _external_ system? → effect is appropriate.

If only 5 applies, write the effect and add a one-line comment naming the external system. Otherwise, delete the effect and use the more direct primitive.

## Rationalization table

| Excuse                                                  | Reality                                                                     |
| ------------------------------------------------------- | --------------------------------------------------------------------------- |
| "I need to know when the popover dismisses"             | Use `onOpenChange`. Unmount is downstream.                                  |
| "I'll invalidate the cache on unmount if a flag is set" | Invalidate on the user action that _caused_ the unmount.                    |
| "The prop might change later, I want to sync"           | Derive at render; `key` if you genuinely need a reset.                      |
| "I need the latest value in a callback"                 | Read from props/state directly — callbacks see the latest render's closure. |
| "It's only a one-line effect"                           | Length isn't the smell. State-from-prop is wrong at any length.             |
| "Existing code does it this way"                        | Existing code may be wrong; verify it's external sync before copying.       |

## Red flags — STOP and use the right primitive

- `useEffect(() => set…(prop), [prop])` — state-from-prop sync
- `useEffect(() => () => { if (flag.current) doX() }, [])` — cleanup-as-side-channel
- A ref mirroring state because "the effect closure is stale"
- Any effect whose body is event-handler logic — handlers belong on the event

When a reviewer flags a `useEffect`, re-read the doc's anti-pattern list first. If it matches one, remove and re-implement with the right primitive. If genuinely external sync, defend it and offer the alternative — let the reviewer make the call.

Source: https://react.dev/learn/you-might-not-need-an-effect
