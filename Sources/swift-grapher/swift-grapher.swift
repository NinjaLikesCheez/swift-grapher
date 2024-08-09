// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser
import Logging
import Foundation
import SwiftGrapher

@main
struct SwiftGrapher: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "swift graph",
		abstract: "Generate relationships between Swift objects",
		version: "0.0.1"
	)

	@Argument(help: "Path to a directory containing Swift files")
	var input: URL

	@Argument(help: "Path to a directory to output GraphViz files")
	var output: URL

	func validate() async throws {
		if !FileManager.default.fileExists(atPath: input.path()) {
			throw ValidationError("Input path \(input.absoluteString) does not exist")
		}

		do {
			try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
		} catch {
			throw ValidationError("Error creating output directory: \(error.localizedDescription)")
		}
	}

	func run() async throws {
		try await validate()

		let module = try Module(path: input)
		let graphs = module.graphs(for: .protocols)
		try graphs.forEach {
			try $0.write(to: output.appending(path: "\($0.id!).dot"))
		}
	}
}

extension URL: @retroactive ExpressibleByArgument {
	public init?(argument: String) {
		self = URL(filePath: argument).absoluteURL
	}
}
