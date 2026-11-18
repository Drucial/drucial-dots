// Counts and classifies the prose comments under a Swift tree and lists what breaks the comment rules.
import Foundation
import SwiftComment

struct Record: Encodable {
  let file: String
  let line: Int
  let lines: Int
  let kind: String
  let decl: String
  let exported: Bool
  let test: Bool
  let violation: String?
  let text: String
}

private let usage =
  "usage: audit [-json file] [-list violations|in-body|all|none] [-match regexp] <root>"

private func padded(_ n: Int, _ width: Int) -> String {
  String(repeating: " ", count: max(0, width - String(n).count)) + String(n)
}

private func printTally(
  _ records: [Record], key: (Record) -> String,
  order: ([(String, Int, Int)]) -> [(String, Int, Int)]
) {
  var lines: [String: Int] = [:]
  var groups: [String: Int] = [:]
  for record in records {
    lines[key(record), default: 0] += record.lines
    groups[key(record), default: 0] += 1
  }
  for (name, count, groupCount) in order(lines.map { ($0.key, $0.value, groups[$0.key]!) }) {
    print("\(padded(count, 6)) lines \(padded(groupCount, 5)) groups  \(name)")
  }
}

private func directory(_ file: String) -> String {
  let dir = (file as NSString).deletingLastPathComponent
  return dir.isEmpty ? "." : dir
}

private func kindLabel(_ record: Record) -> String {
  if record.kind == "file" { return "file" }
  let scope = record.test ? "test" : record.exported ? "exported" : "unexported"
  return "\(scope) \(record.kind)"
}

var jsonPath = ""
var list = "violations"
var match = ""
var positional: [String] = []
var arguments = Array(CommandLine.arguments.dropFirst()).makeIterator()
while let argument = arguments.next() {
  switch argument.replacingOccurrences(of: "--", with: "-") {
  case "-json": jsonPath = arguments.next() ?? ""
  case "-list": list = arguments.next() ?? ""
  case "-match": match = arguments.next() ?? ""
  default: positional.append(argument)
  }
}
guard positional.count == 1, ["violations", "in-body", "all", "none"].contains(list) else {
  printError(usage)
  exit(2)
}
var pattern: NSRegularExpression?
if !match.isEmpty {
  do {
    pattern = try NSRegularExpression(pattern: match)
  } catch {
    printError("bad -match pattern: \(error)")
    exit(2)
  }
}

var records: [Record] = []
walk(positional[0]) { rel, tree in
  for group in classify(tree, file: rel) where !group.directive {
    records.append(
      Record(
        file: rel, line: group.startLine, lines: group.lines, kind: group.kind, decl: group.decl,
        exported: group.exported, test: group.test,
        violation: group.violation.isEmpty ? nil : group.violation, text: group.text
      )
    )
  }
}

if !jsonPath.isEmpty {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
  do {
    try encoder.encode(records).write(to: URL(fileURLWithPath: jsonPath))
  } catch {
    printError("\(error)")
    exit(1)
  }
}

print("== comment lines by package (total \(records.reduce(0) { $0 + $1.lines }))")
printTally(records, key: { directory($0.file) }) { rows in
  rows.sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0 < $1.0 }
}
print("== by kind")
printTally(records, key: kindLabel) { rows in rows.sorted { $0.0 < $1.0 } }

let violations = records.filter { $0.violation != nil }
print("== violations: \(violations.count)")
if list != "none" {
  let picked = records.filter { record in
    let listed =
      list == "all" || (list == "violations" && record.violation != nil)
      || (list == "in-body" && record.kind == "in-body")
    let range = NSRange(record.text.startIndex..., in: record.text)
    return listed && (pattern == nil || pattern!.firstMatch(in: record.text, range: range) != nil)
  }
  print("== \(list) (\(picked.count))")
  for record in picked {
    var label = record.kind
    if !record.decl.isEmpty { label += " \(record.decl)" }
    if let violation = record.violation { label += ", \(violation)" }
    print("\(record.file):\(record.line) [\(label)]")
    for line in record.text.split(separator: "\n", omittingEmptySubsequences: false) {
      print("    \(line)")
    }
  }
}
