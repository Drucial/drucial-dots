// Finds and classifies every comment in a Swift file, using swift-syntax.
import Foundation
import SwiftParser
import SwiftSyntax

/// One comment as written, with UTF-8 byte offsets into the file.
public struct Comment: Sendable {
  public let text: String
  public let start: Int
  public let end: Int
}

/// One comment group with what it is attached to.
public struct Group: Sendable {
  public let file: String
  public let startLine: Int
  public let endLine: Int
  public let kind: String
  public let decl: String
  public let exported: Bool
  public let test: Bool
  public let comments: [Comment]

  public var text: String { comments.map(\.text).joined(separator: "\n") }

  public var lines: Int { endLine - startLine + 1 }

  /// True when every comment in the group is tooling rather than prose.
  public var directive: Bool { comments.allSatisfy { isDirective($0.text) } }

  /// The longest the rules allow this group to be, in lines.
  public var limit: Int { exported && kind != "file" ? 3 : 1 }

  /// The rule this group breaks, or empty.
  public var violation: String {
    if directive { return "" }
    if kind == "in-body" { return "inside a function body" }
    if kind == "floating" { return "not attached to a declaration" }
    if lines > limit { return "over its length limit" }
    return ""
  }
}

private let directiveMarkers = [
  "swiftlint:disable", "swiftlint:enable", "swift-format-ignore", "swiftformat:",
  "periphery:ignore", "sourcery:",
]

private let generatedMarkers = [
  "generated using", "@generated", "auto-generated", "code generated", "do not edit",
]

private let skippedDirectories: Set<String> = [
  ".build", "vendor", "Pods", "Carthage", "DerivedData", "node_modules",
]

/// Reports whether a single comment is tooling rather than prose.
public func isDirective(_ text: String) -> Bool {
  let body = text.drop { $0 == "/" || $0 == "*" }.drop { $0 == " " }
  return body.hasPrefix("swift-tools-version") || directiveMarkers.contains { text.contains($0) }
}

/// Reports whether the file's first lines mark it as generated.
public func isGenerated(_ source: String) -> Bool {
  let head = source.split(separator: "\n", maxSplits: 6, omittingEmptySubsequences: false)
    .prefix(6).joined(separator: "\n").lowercased()
  return generatedMarkers.contains { head.contains($0) }
}

/// Reports whether a repo-relative path is test code.
public func isTest(_ path: String) -> Bool {
  let parts = path.split(separator: "/")
  return path.hasSuffix("Tests.swift") || parts.dropLast().contains { $0.hasSuffix("Tests") }
}

/// Parses source, returning nil for a generated file.
public func parseFile(_ source: String) -> SourceFileSyntax? {
  isGenerated(source) ? nil : Parser.parse(source: source)
}

/// Splits arguments that each hold a space-separated list of paths.
public func splitArguments(_ args: [String]) -> [String] {
  args.flatMap { $0.split(whereSeparator: \.isWhitespace).map(String.init) }
}

/// Writes message and a newline to standard error.
public func printError(_ message: String) {
  FileHandle.standardError.write(Data((message + "\n").utf8))
}

/// Runs git with args and returns its standard output, or nil when it exits nonzero.
public func git(_ args: [String]) -> Data? {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  process.arguments = ["git"] + args
  let pipe = Pipe()
  process.standardOutput = pipe
  process.standardError = FileHandle.nullDevice
  do {
    try process.run()
  } catch {
    return nil
  }
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  process.waitUntilExit()
  return process.terminationStatus == 0 ? data : nil
}

/// Every comment in the file in source order.
public func comments(in tree: SourceFileSyntax) -> [Comment] {
  rawGroups(tree).flatMap(\.comments)
}

/// Every comment group in the tree, classified against the comment rules. `file` is the repo-relative path.
public func classify(_ tree: SourceFileSyntax, file: String) -> [Group] {
  let converter = SourceLocationConverter(fileName: file, tree: tree)
  let bodies = bodyRanges(tree)
  let test = isTest(file)
  let firstToken = tree.firstToken(viewMode: .sourceAccurate)
  let line = { (offset: Int) in converter.location(for: AbsolutePosition(utf8Offset: offset)).line }

  return rawGroups(tree).map { raw in
    let start = raw.comments[0].start
    let end = raw.comments[raw.comments.count - 1].end
    var kind = "floating"
    var decl = ""
    var exported = false
    if bodies.contains(where: { start >= $0.lowerBound && end <= $0.upperBound }) {
      kind = "in-body"
    } else if !raw.leading {
      kind = "trailing"
      decl = enclosingDecl(Syntax(raw.token)).map(declName) ?? ""
    } else if raw.newlinesToToken >= 2 {
      if raw.token == firstToken { kind = "file" }
    } else if let owner = owningDecl(raw.token) {
      kind = declKind(owner)
      decl = declName(owner)
      exported = !test && isExported(owner)
    }
    return Group(
      file: file, startLine: line(start), endLine: line(end), kind: kind, decl: decl,
      exported: exported, test: test, comments: raw.comments
    )
  }
}

/// Calls body for every non-generated Swift file under root with its path relative to root.
public func walk(_ root: String, _ body: (String, SourceFileSyntax) -> Void) {
  for rel in sources(root) {
    guard let source = try? String(contentsOfFile: root + "/" + rel, encoding: .utf8),
      let tree = parseFile(source)
    else { continue }
    body(rel, tree)
  }
}

private func sources(_ root: String) -> [String] {
  var files: [String]
  if let out = git([
    "-C", root, "ls-files", "--cached", "--others", "--exclude-standard", "--", "*.swift",
  ]) {
    files = String(decoding: out, as: UTF8.self).split(separator: "\n").map(String.init)
  } else {
    let enumerator = FileManager.default.enumerator(atPath: root)
    files = []
    while let path = enumerator?.nextObject() as? String {
      if path.hasSuffix(".swift") { files.append(path) }
    }
  }
  return files.filter { path in
    !path.split(separator: "/").dropLast().contains {
      skippedDirectories.contains(String($0)) || $0.hasPrefix(".")
    }
      && FileManager.default.fileExists(atPath: root + "/" + path)
  }.sorted()
}

private struct RawGroup {
  var comments: [Comment]
  let token: TokenSyntax
  let leading: Bool
  var newlinesToToken = 0
}

private func rawGroups(_ tree: SourceFileSyntax) -> [RawGroup] {
  var out: [RawGroup] = []
  for token in tree.tokens(viewMode: .sourceAccurate) {
    out += groups(
      in: token.leadingTrivia, at: token.position.utf8Offset, token: token, leading: true)
    out += groups(
      in: token.trailingTrivia, at: token.endPositionBeforeTrailingTrivia.utf8Offset, token: token,
      leading: false
    )
  }
  return out
}

private func groups(in trivia: Trivia, at offset: Int, token: TokenSyntax, leading: Bool)
  -> [RawGroup]
{
  var found: [RawGroup] = []
  var newlinesAtEnd: [Int] = []
  var position = offset
  var newlines = 0
  var sinceComment = 0
  for piece in trivia {
    let start = position
    position += piece.sourceLength.utf8Length
    switch piece {
    case .lineComment(let text), .docLineComment(let text), .blockComment(let text),
      .docBlockComment(let text):
      let comment = Comment(text: text, start: start, end: position)
      if let last = found.last?.comments.last, sinceComment == 1, text.hasPrefix("//"),
        last.text.hasPrefix("//"), isDirective(text) == isDirective(last.text)
      {
        found[found.count - 1].comments.append(comment)
        newlinesAtEnd[found.count - 1] = newlines
      } else {
        found.append(RawGroup(comments: [comment], token: token, leading: leading))
        newlinesAtEnd.append(newlines)
      }
      sinceComment = 0
    case .newlines(let n), .carriageReturns(let n), .carriageReturnLineFeeds(let n):
      newlines += n
      sinceComment += n
    default:
      break
    }
  }
  for i in found.indices {
    found[i].newlinesToToken = newlines - newlinesAtEnd[i]
  }
  return found
}

private func bodyRanges(_ tree: SourceFileSyntax) -> [ClosedRange<Int>] {
  var out: [ClosedRange<Int>] = []
  func add(_ left: TokenSyntax, _ right: TokenSyntax) {
    let lower = left.endPositionBeforeTrailingTrivia.utf8Offset
    let upper = right.positionAfterSkippingLeadingTrivia.utf8Offset
    if lower <= upper { out.append(lower...upper) }
  }
  func visit(_ node: Syntax) {
    if let body = node.as(FunctionDeclSyntax.self)?.body {
      add(body.leftBrace, body.rightBrace)
    } else if let body = node.as(InitializerDeclSyntax.self)?.body {
      add(body.leftBrace, body.rightBrace)
    } else if let body = node.as(DeinitializerDeclSyntax.self)?.body {
      add(body.leftBrace, body.rightBrace)
    } else if let body = node.as(AccessorDeclSyntax.self)?.body {
      add(body.leftBrace, body.rightBrace)
    } else if let closure = node.as(ClosureExprSyntax.self) {
      add(closure.leftBrace, closure.rightBrace)
    } else if let block = node.as(AccessorBlockSyntax.self), case .getter = block.accessors {
      add(block.leftBrace, block.rightBrace)
    }
    for child in node.children(viewMode: .sourceAccurate) {
      visit(child)
    }
  }
  visit(Syntax(tree))
  return out
}

private func isDecl(_ node: Syntax) -> Bool {
  node.asProtocol(DeclSyntaxProtocol.self) != nil
}

private func owningDecl(_ token: TokenSyntax) -> Syntax? {
  var owner: Syntax?
  var node = Syntax(token).parent
  while let current = node, current.firstToken(viewMode: .sourceAccurate) == token {
    if isDecl(current) { owner = current }
    node = current.parent
  }
  return owner
}

private func enclosingDecl(_ node: Syntax) -> Syntax? {
  var parent = node.parent
  while let current = parent {
    if isDecl(current) && !current.is(IfConfigDeclSyntax.self) { return current }
    parent = current.parent
  }
  return nil
}

private func declaredExport(_ decl: Syntax) -> Bool? {
  guard let modifiers = decl.asProtocol(WithModifiersSyntax.self)?.modifiers else { return nil }
  for modifier in modifiers where modifier.detail == nil {
    switch modifier.name.tokenKind {
    case .keyword(.public), .keyword(.open), .keyword(.package): return true
    case .keyword(.internal), .keyword(.private), .keyword(.fileprivate): return false
    default: continue
    }
  }
  return nil
}

private func isExported(_ decl: Syntax) -> Bool {
  if let declared = declaredExport(decl) { return declared }
  guard let parent = enclosingDecl(decl) else { return false }
  if parent.is(ExtensionDeclSyntax.self) { return declaredExport(parent) == true }
  if parent.is(ProtocolDeclSyntax.self)
    || (parent.is(EnumDeclSyntax.self) && decl.is(EnumCaseDeclSyntax.self))
  {
    return isExported(parent)
  }
  return false
}

private func declKind(_ decl: Syntax) -> String {
  if let variable = decl.as(VariableDeclSyntax.self) { return variable.bindingSpecifier.text }
  let name = String(describing: decl.syntaxNodeType).replacingOccurrences(
    of: "DeclSyntax", with: "")
  return name.prefix(1).lowercased() + name.dropFirst()
}

private func declName(_ decl: Syntax) -> String {
  if let named = decl.asProtocol(NamedDeclSyntax.self) { return named.name.text }
  if let variable = decl.as(VariableDeclSyntax.self) {
    return variable.bindings.map(\.pattern.trimmedDescription).joined(separator: ", ")
  }
  if let cases = decl.as(EnumCaseDeclSyntax.self) {
    return cases.elements.map(\.name.text).joined(separator: ", ")
  }
  if let ext = decl.as(ExtensionDeclSyntax.self) { return ext.extendedType.trimmedDescription }
  if let imp = decl.as(ImportDeclSyntax.self) { return imp.path.trimmedDescription }
  if decl.is(InitializerDeclSyntax.self) { return "init" }
  if decl.is(DeinitializerDeclSyntax.self) { return "deinit" }
  if decl.is(SubscriptDeclSyntax.self) { return "subscript" }
  return declKind(decl)
}
