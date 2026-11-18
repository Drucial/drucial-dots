// Deletes every comment from the given Swift files except tooling directives.
import Foundation
import SwiftComment

private let newline = UInt8(ascii: "\n")

private func isSpace(_ byte: UInt8) -> Bool {
  byte == UInt8(ascii: " ") || byte == UInt8(ascii: "\t") || byte == UInt8(ascii: "\r")
}

private func isBlank(_ bytes: ArraySlice<UInt8>) -> Bool {
  bytes.allSatisfy(isSpace)
}

private func trimmedEnd(_ bytes: ArraySlice<UInt8>) -> ArraySlice<UInt8> {
  var end = bytes.endIndex
  while end > bytes.startIndex && isSpace(bytes[end - 1]) { end -= 1 }
  return bytes[bytes.startIndex..<end]
}

private func trimmed(_ bytes: [UInt8]) -> ArraySlice<UInt8> {
  let end = trimmedEnd(bytes[...])
  return end.drop(while: isSpace)
}

private func strip(_ path: String) throws -> Int? {
  let source = try String(contentsOfFile: path, encoding: .utf8)
  guard let tree = parseFile(source) else { return nil }
  let doomed = comments(in: tree).filter { !isDirective($0.text) }.sorted { $0.start > $1.start }

  let bytes = Array(source.utf8)
  var lineStarts = [0]
  for (i, byte) in bytes.enumerated() where byte == newline {
    lineStarts.append(i + 1)
  }
  var lines: [[UInt8]] = lineStarts.indices.map { i in
    let end = i + 1 < lineStarts.count ? lineStarts[i + 1] - 1 : bytes.count
    return Array(bytes[lineStarts[i]..<end])
  }
  func locate(_ offset: Int) -> (line: Int, column: Int) {
    var low = 0
    var high = lineStarts.count - 1
    while low < high {
      let mid = (low + high + 1) / 2
      if lineStarts[mid] <= offset { low = mid } else { high = mid - 1 }
    }
    return (low, offset - lineStarts[low])
  }

  var gone = [Bool](repeating: false, count: lines.count)
  var touched = [Bool](repeating: false, count: lines.count)
  for comment in doomed {
    let (startLine, startColumn) = locate(comment.start)
    let (endLine, endColumn) = locate(comment.end)
    let before = lines[startLine][..<startColumn]
    let after = lines[endLine][endColumn...]
    if isBlank(before) && isBlank(after) {
      for l in startLine...endLine { gone[l] = true }
      if startLine > 0 { touched[startLine - 1] = true }
      if endLine + 1 < lines.count { touched[endLine + 1] = true }
      continue
    }
    if startLine == endLine {
      let gap: [UInt8] = !isBlank(before) && !isBlank(after) ? [UInt8(ascii: " ")] : []
      lines[startLine] = Array(trimmedEnd(before)) + gap + Array(after)
      continue
    }
    lines[startLine] = Array(trimmedEnd(before))
    for l in startLine + 1..<endLine { gone[l] = true }
    lines[endLine] = Array(after)
  }

  var out: [[UInt8]] = []
  for (i, line) in lines.enumerated() where !gone[i] {
    if isBlank(line[...]) && touched[i] {
      let previous = out.last.map(trimmed) ?? []
      let next = lines.indices.dropFirst(i + 1).first { !gone[$0] }.map { trimmed(lines[$0]) } ?? []
      let opens = previous.last.map { "{([".utf8.contains($0) } ?? false
      let closes = next.first.map { "})]".utf8.contains($0) } ?? false
      if previous.isEmpty || opens || closes { continue }
    }
    out.append(line)
  }
  try Data(out.joined(separator: [newline])).write(to: URL(fileURLWithPath: path))
  return doomed.count
}

let paths = splitArguments(Array(CommandLine.arguments.dropFirst()))
if paths.isEmpty {
  printError("usage: strip <file.swift>...")
  exit(2)
}
var failed = false
for path in paths {
  do {
    if let count = try strip(path) {
      print("stripped \(count) comments: \(path)")
    } else {
      print("skipped (generated): \(path)")
    }
  } catch {
    printError("\(path): \(error)")
    failed = true
  }
}
exit(failed ? 1 : 0)
