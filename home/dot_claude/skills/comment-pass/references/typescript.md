# TypeScript and JavaScript

## Tools

No dependencies of their own. They load `typescript` from the target repo's `node_modules`, so install dependencies first. Node 18 or newer.

```sh
node <skill>/tools/typescript/cli.mjs <command> ...
```

| Command | Use |
|---|---|
| `strip <file>...` | Deletes every comment except directives. Accepts one argument holding a space-separated list. Skips generated files. |
| `same <repo> <base-ref> [file...]` | Compares each file's token stream to the base with comments skipped. Prints `comments only`, `unchanged`, `CODE CHANGED near token N`, `PARSE ERRORS CHANGED` or `DIRECTIVE REMOVED`, and exits 1 on any failure. With no files, checks every source file changed since the base. |
| `audit [-json f] [-list violations\|in-body\|all\|none] [-match re] <root>` | Comment lines per directory and per kind, then the listed groups in full. Uses `git ls-files`, and skips `node_modules`, build output, minified and generated files. |

Sources are `.ts`, `.tsx`, `.mts`, `.cts`, `.js`, `.jsx`, `.mjs` and `.cjs`. Vue, Svelte and Astro files are not supported; list them in the report as skipped.

## Batching unit

A directory, or a workspace package in a monorepo. Keep a file with its `*.test.*`, `*.spec.*` or `__tests__` neighbors.

## Protected, never stripped

- **Type and lint directives:** `@ts-expect-error`, `@ts-ignore`, `@ts-nocheck`, `@ts-check`, `eslint-disable`/`enable`/`env`, `/* global */`, `biome-ignore`, `prettier-ignore`, `oxlint-disable`, `deno-lint-ignore`, `dprint-ignore`, `tslint:`
- **Coverage:** `istanbul ignore`, `c8 ignore`, `v8 ignore`
- **Bundler:** `@vite-ignore`, `webpackChunkName` and the other webpack magic comments, `#__PURE__`, `@__NO_SIDE_EFFECTS__`
- **JSX and test runners:** `@jsx`, `@jsxImportSource`, `@jsxRuntime`, `@jsxFrag`, `@vitest-environment`, `@jest-environment`, `@refresh`, `@flow`
- **Legal and references:** `/*!` headers, `@license`, `@preserve`, `/// <reference>`
- **JSDoc that carries types in a `.js` file:** `@type`, `@param`, `@returns`, `@typedef`, `@template` and so on. In a checked JS project those are the types.

`"use client"` and `"use server"` are strings, not comments, and never touched.

## What counts as exported

- A declaration with `export`, or `export default`.
- Public and protected members of an exported class, interface or type.
- Everything in a `.d.ts` file.
- Never anything in a test file.

App repos export nearly everything (components, route handlers, hooks), so most exported docs still fail the "the name and signature already say it" test. A props interface usually says what the component takes.

## JSX

- A line holding only `{/* ... */}` is removed along with its braces.
- `same` treats an empty `{}` JSX expression as nothing and collapses whitespace in JSX text.
- `//` inside JSX text is text, and is never touched.

## Preflight grep

Source that reads comments:

```sh
grep -rlE 'CommentRanges|leadingComments|trailingComments|getJsDocs|extractComments|comment-json' --exclude-dir=node_modules --include='*.[jt]s' --include='*.[jt]sx' --include='*.m[jt]s' .
```

A hit in a test, codemod or build script stops the run until the user decides.

## Checks per commit

Resolve the package manager from the lockfile: `pnpm-lock.yaml`, `yarn.lock`, `bun.lock` or `bun.lockb`, else npm. Then use the repo's scripts.

- **Format.** Run the formatter on the changed files after stripping: `prettier --write <files>` or `biome format --write <files>`. The check must then pass. Stripping routinely leaves lines the formatter rewraps; on wire, 7 of 144 files needed it.
- **Typecheck, every commit.** The `typecheck` script, or `tsc --noEmit`. `same` protects the directives it knows about, but a type-bearing comment outside that list only shows up here.
- **Lint.** The `lint` script, on the changed files where it accepts paths.

## Full check

The repo's `check` script plus `test`, or whatever its CLAUDE.md or AGENTS.md names.

## Known behavior

- A top-level `{/* note */}` outside JSX is a block statement. The stripper leaves `{ }` there rather than deleting code.
- Verified on wire: 144 files stripped, `same` passed on all of them, and `tsc --noEmit` stayed clean. A changed literal and a deleted `@ts-expect-error` were both caught.
