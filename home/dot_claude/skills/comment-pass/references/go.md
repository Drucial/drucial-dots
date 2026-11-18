# Go

## Tools

Standard library only. Build once per session:

```sh
cd <skill>/tools/go && go build -o <scratch>/bin/ ./cmd/...
```

| Command | Use |
|---|---|
| `strip <file.go>...` | Deletes every comment except directives. Accepts one argument holding a space-separated list. Skips generated files. |
| `same <repo> <base-ref> [file.go...]` | Compares each file to the base with comments removed. Prints `comments only`, `unchanged`, `CODE CHANGED` or `DIRECTIVE REMOVED`, and exits 1 on any failure. With no files, checks every `.go` file changed since the base. |
| `audit [-json f] [-list violations\|in-body\|all\|none] [-match re] <root>` | Comment lines per package and per kind, then the listed groups in full. Skips vendor, testdata and generated files. |

## Batching unit

A package directory. Keep `foo.go` with `foo_test.go`.

## Protected, never stripped

- `//go:` directives, `//nolint`, `//lint:`, `//export`, `//extern`, `//line`, `// +build`
- A cgo preamble, meaning the comment directly above `import "C"`
- `// Output:` and `// Unordered output:` in example tests, which `go test` checks
- Files marked `// Code generated ... DO NOT EDIT.`

## What counts as exported

- An exported identifier.
- A method, only when its receiver type is exported too.
- A field, only when both it and its type are exported.
- Never anything in a `_test.go` file.

`audit` enforces a 3-line limit on exported docs, 1 line on everything else.

## Preflight grep

Source that reads comments:

```sh
grep -rlE 'go/doc|ParseComments|ast\.CommentGroup|CommentMap' --include='*.go' .
```

A hit in a test or generator stops the run until the user decides.

## Checks per commit

- Format: `gofmt -l <files>` prints nothing. Run `gofmt -w <files>` after stripping.
- Lint: `golangci-lint run ./<package>/...` if the repo configures it, otherwise `go vet ./<package>/...`.

## Full check

The Makefile's `all` or `check` target if there is one, otherwise:

```sh
go build ./... && go vet ./... && go test ./...
```

## Known behavior

- The stripper can leave a blank line inside a struct, const or interface block where a comment used to separate groups. gofmt accepts it, and agents may remove it. `same` ignores whitespace.
- Verified on zen-octo: 197 files stripped, `same` passed on all of them, and build and vet stayed clean. A changed constant and a deleted `//nolint` were both caught.
