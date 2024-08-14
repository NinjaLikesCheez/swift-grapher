import ArgumentParser
import Foundation
import Logging
import SwiftGrapher

@main
struct SwiftGrapher: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "swift-grapher",
		abstract: "Generate relationships between Swift protocols",
		version: "0.0.1"
	)

	@Argument(help: "Path to a directory containing Swift files")
	var input: URL

	@Argument(help: "Path to a directory to output GraphViz files")
	var output: URL

	@Flag(help: "Enable debug logging")
	var debug: Bool = false

	@Option(help: "Filter out protocols with more restrictive visibility than this")
	var visibility: VisibilityModifier = .open

	mutating func validate() async throws {
		LoggingSystem.bootstrap { [debug] label in
			let level: Logger.Level = debug ? .debug : .info
			return StandardStreamLogHandler(label, level: level, metadata: [:])
		}

		if !FileManager.default.fileExists(atPath: input.path()) {
			throw ValidationError("Input path \(input.absoluteString) does not exist")
		}

		do {
			try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
		} catch {
			throw ValidationError("Error creating output directory: \(error.localizedDescription)")
		}
	}

	mutating func run() async throws {
		// For some unknown reason this isn't being called by the framework
		try await validate()

		var module = try Module(path: input, visibility: visibility)

		try module
			.graphs(for: .protocols)
			.forEach {
				try $0.write(to: output.appending(path: "\($0.id!).dot"))
			}
	}
}

extension URL: @retroactive ExpressibleByArgument {
	public init?(argument: String) {
		self = URL(filePath: argument).absoluteURL
	}
}

extension VisibilityModifier: @retroactive ExpressibleByArgument {}
