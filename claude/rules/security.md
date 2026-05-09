---
paths:
  - "**/api/**"
  - "**/auth/**"
  - "**/middleware.ts"
  - "**/middleware/**"
  - "**/route.ts"
  - "**/lib/auth*"
---

# Security

## Input validation

- Validate every external input with Zod. No exceptions for "trusted" callers — trust ends at the network boundary.
- Validate at the API route or server action entry. Don't push validation deeper.

## Database

- Use Drizzle/Prisma query builders only. Never raw SQL with string interpolation.
- If you must use raw SQL, use parameterized queries (Drizzle's `sql` template handles this when interpolating values).

## Sessions and auth

- Session tokens in **httpOnly cookies** only. Never `localStorage`. Never readable by JS.
- Never log: request bodies, auth headers, cookies, password fields, tokens.
- Compare tokens with constant-time comparison (avoid early-exit string compare).

## API surface

- Public endpoints get rate limiting (Upstash Ratelimit, custom middleware, or platform-provided).
- CSRF: server actions are protected by Next.js by default. Custom API routes that mutate state need explicit CSRF protection if cookie-authenticated.
- Security headers (CSP, HSTS, X-Frame-Options, X-Content-Type-Options) via `middleware.ts` or `next.config.js`.

## Errors

- Server-side: log full error with context.
- Client-facing: return generic message — don't leak stack traces, query strings, or internal paths.
- 401/403 vs 404: don't reveal resource existence to unauthorized users (return 404 instead of 403 for sensitive resources).

## Secrets

- Never log, embed, or commit secrets. The `scan-secrets.sh` hook catches obvious cases — don't rely on it as your only defense.
- Server-only env vars: `process.env.X` only in server-side code (server components, actions, API routes). Never in `'use client'` files.
- Public env vars: `NEXT_PUBLIC_*` prefix is required and signals "this is shipped to the browser" — review before adding.
