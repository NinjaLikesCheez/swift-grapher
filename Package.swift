// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "swift-grapher",
	platforms: [
		.macOS(.v14)
	],
	products: [
		.executable(name: "swift-grapher", targets: ["swift-grapher"]),
		.library(name: "SwiftGrapher", targets: ["SwiftGrapher"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "510.0.3"),
		.package(url: "https://github.com/apple/swift-log.git", from: "1.6.1")
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "SwiftGrapher",
			dependencies: [
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftParser", package: "swift-syntax"),
				.product(name: "SwiftDiagnostics", package: "swift-syntax"),
				.product(name: "Logging", package: "swift-log")
			]
		),
		.executableTarget(
			name: "swift-grapher",
			dependencies: [
				.target(name: "SwiftGrapher"),
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "Logging", package: "swift-log")
			]
		)
	]
)
