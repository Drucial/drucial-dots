# Swift

## Tools

A SwiftPM package that depends only on swift-syntax, pinned to 602.x by `Package.resolved`. It never touches the target repo's dependencies. Build once per session; the first build fetches and compiles swift-syntax, which takes a few minutes:

```sh
swift build -c release --package-path <skill>/tools/swift --scratch-path <scratch>/swift-build
```

The binaries land in `<scratch>/swift-build/release/`.

| Command | Use |
|---|---|
| `strip <file.swift>...` | Deletes every comment except directives. Accepts one argument holding a space-separated list. Skips generated files. |
| `same <repo> <base-ref> [file.swift...]` | Compares each file to the base with trivia removed: tokens, syntax tree shape and parse-error count. Prints `comments only`, `unchanged`, `CODE CHANGED near token N`, `CODE CHANGED (syntax tree)`, `PARSE ERRORS CHANGED` or `DIRECTIVE REMOVED`, and exits 1 on any failure. With no files, checks every `.swift` file changed since the base. |
| `audit [-json f] [-list violations\|in-body\|all\|none] [-match re] <root>` | Comment lines per directory and per kind, then the listed groups in full. Uses `git ls-files`, and skips `.build`, `vendor`, `Pods`, `Carthage`, `DerivedData` and generated files. |

## Batching unit

A SwiftPM target: `Sources/<Target>` together with `Tests/<Target>Tests`. In an Xcode project, a top-level group directory with its test target's directory.

## Protected, never stripped

- `// swift-tools-version:` in `Package.swift`
- `swiftlint:disable` and `swiftlint:enable`, including `:next`, `:this` and `:previous`
- `swift-format-ignore`, `swift-format-ignore-file`, `swiftformat:`
- `periphery:ignore`, `sourcery:`
- Files whose first lines say `Generated using`, `@generated`, `auto-generated`, `Code generated` or `DO NOT EDIT`

`// MARK:`, `// TODO:` and license headers are prose and are stripped. A MARK is a banner.

## What counts as exported

- A declaration marked `public`, `open` or `package`.
- A member without its own access modifier inside a `public` or `package` extension.
- An enum case of an exported enum, and a requirement of an exported protocol.
- Never anything in a test file: a path under a directory ending in `Tests`, or a name ending in `Tests.swift`.

An app target is mostly `internal`, so most of its docs are held to the 1-line limit. `audit` enforces 3 lines on exported docs and 1 on everything else.

## Preflight grep

Source that reads comments:

```sh
grep -rlE 'SwiftSyntax|Trivia|leadingTrivia|SourceKitten|docComment' --include='*.swift' --exclude-dir=.build .
find . -name '*.docc' -not -path './.build/*'
```

A hit in a test, macro or build plugin stops the run until the user decides. A DocC catalog renders doc comments as published documentation, so it stops the run too.

## Checks per commit

Run each tool only on the paths the repo's own check covers, for example `Sources Tests`. `swift format` rewrites more than whitespace, and outside that scope it can drop trailing commas, which `same` rightly fails.

- **Format.** With `.swift-format`: `swift format --in-place <files>`, then `swift format lint --strict <files>`. With `.swiftformat`: `swiftformat <files>`, then `swiftformat --lint <files>`. With neither, don't format.
- **Lint.** With `.swiftlint.yml`: `swiftlint lint --strict --quiet <files>`.

## Full check

The script the repo's CLAUDE.md or AGENTS.md names, such as `bin/check`. Otherwise `swift build && swift test`, or `xcodebuild build test -scheme <scheme>` for an Xcode project.

## Known behavior

- Removing a comment from the middle of a line leaves a double space. The formatter removes it, and `same` ignores whitespace.
- Verified on zen-term: 386 files stripped, 379 changed, and `same` passed on all of them. Build, 2,156 tests, `swift format lint --strict` and `swiftlint --strict` stayed clean. A changed literal, a deleted `swiftlint:disable:next`, removed operator spacing, a call split across lines, and trailing commas `swift format` dropped outside the repo's format scope were all caught.
- A block comment spanning lines between two tokens leaves them on separate lines. `same` compares the syntax tree, so it catches the rare case where that line break changes how Swift parses the code, such as a call turning into a separate statement.
