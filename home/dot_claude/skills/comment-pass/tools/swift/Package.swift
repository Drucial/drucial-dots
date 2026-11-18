// swift-tools-version: 6.0
import PackageDescription

let syntax: [Target.Dependency] = [
  .product(name: "SwiftSyntax", package: "swift-syntax"),
  .product(name: "SwiftParser", package: "swift-syntax"),
]

let package = Package(
  name: "commentpass",
  platforms: [.macOS(.v13)],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", from: "602.0.0")
  ],
  targets: [
    .target(name: "SwiftComment", dependencies: syntax),
    .executableTarget(name: "strip", dependencies: ["SwiftComment"]),
    .executableTarget(
      name: "same",
      dependencies: [
        "SwiftComment", .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
      ] + syntax
    ),
    .executableTarget(name: "audit", dependencies: ["SwiftComment"]),
  ]
)
