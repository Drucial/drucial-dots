// Proves Swift files differ from a git ref by comments alone, and that no tooling directive was lost.
import Foundation
import SwiftComment
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax

struct Shape {
  let tokens: [String]
  let nodes: [String]
  let directives: [String]
  let errors: Int

  init(_ source: String) {
    let tree = Parser.parse(source: source)
    tokens = tree.tokens(viewMode: .sourceAccurate).map { "\($0.tokenKind) \($0.text)" }
    var nodes: [String] = []
    func record(_ node: Syntax) {
      if node.is(TokenSyntax.self) { return }
      nodes.append("\(node.kind)")
      for child in node.children(viewMode: .sourceAccurate) {
        record(child)
      }
      nodes.append(")")
    }
    record(Syntax(tree))
    self.nodes = nodes
    directives = comments(in: tree).filter { isDirective($0.text) }.map {
      $0.text.trimmingCharacters(in: .whitespaces)
    }
    errors = ParseDiagnosticsGenerator.diagnostics(for: tree).count
  }
}

private func compare(repo: String, base: String, file: String) -> String {
  guard let old = git(["-C", repo, "show", "\(base):\(file)"]) else {
    return "CODE CHANGED (not in base)"
  }
  guard let current = FileManager.default.contents(atPath: repo + "/" + file) else {
    return "CODE CHANGED (deleted)"
  }
  if old == current { return "unchanged" }

  let a = Shape(String(decoding: old, as: UTF8.self))
  let b = Shape(String(decoding: current, as: UTF8.self))
  if a.errors != b.errors { return "PARSE ERRORS CHANGED" }
  if a.tokens != b.tokens {
    let i = zip(a.tokens, b.tokens).enumerated().first { $1.0 != $1.1 }?.offset ?? min(a.tokens.count, b.tokens.count)
    let was = i < a.tokens.count ? a.tokens[i] : "end"
    let now = i < b.tokens.count ? b.tokens[i] : "end"
    return "CODE CHANGED near token \(i): \(was) -> \(now)"
  }
  if a.nodes != b.nodes { return "CODE CHANGED (syntax tree)" }
  let missing = lost(a.directives, b.directives)
  if !missing.isEmpty { return "DIRECTIVE REMOVED " + missing.joined(separator: ", ") }
  return "comments only"
}

private func lost(_ before: [String], _ after: [String]) -> [String] {
  var have: [String: Int] = [:]
  for directive in after { have[directive, default: 0] += 1 }
  var missing: [String] = []
  for directive in before {
    if let count = have[directive], count > 0 {
      have[directive] = count - 1
    } else {
      missing.append(directive)
    }
  }
  return missing.sorted()
}

let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 2 else {
  printError("usage: same <repo> <base-ref> [file.swift...]")
  exit(2)
}
let repo = URL(fileURLWithPath: args[0]).resolvingSymlinksInPath().path
let base = args[1]
var paths = splitArguments(Array(args.dropFirst(2)))
if paths.isEmpty {
  guard let out = git(["-C", repo, "diff", "--name-only", base, "--", "*.swift"]) else {
    printError("git diff failed against \(base)")
    exit(2)
  }
  paths = String(decoding: out, as: UTF8.self).split(separator: "\n").map(String.init)
}
paths = paths.map { path in
  guard path.hasPrefix("/") else { return path }
  let resolved = URL(fileURLWithPath: path).resolvingSymlinksInPath().path
  return resolved.hasPrefix(repo + "/") ? String(resolved.dropFirst(repo.count + 1)) : path
}

var bad = 0
for path in paths {
  let verdict = compare(repo: repo, base: base, file: path)
  print("\(verdict): \(path)")
  if verdict != "comments only" && verdict != "unchanged" { bad += 1 }
}
print("\(paths.count) files, \(bad) failing")
exit(bad > 0 ? 1 : 0)
