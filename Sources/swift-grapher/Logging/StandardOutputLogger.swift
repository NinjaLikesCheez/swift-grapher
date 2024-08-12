import Foundation
import Logging

struct StandardOutputTextStream: TextOutputStream, @unchecked Sendable {
	static let stdout = StandardOutputTextStream(file: Darwin.stdout)
	static let stderr = StandardOutputTextStream(file: Darwin.stderr)

	let file: UnsafeMutablePointer<FILE>

	func write(_ string: String) {
		var string = string
		string.makeContiguousUTF8()
		string.utf8.withContiguousStorageIfAvailable { bytes in
			flockfile(file)
			fwrite(bytes.baseAddress!, 1, bytes.count, file)
			fflush(file)
			funlockfile(file)
		}
	}
}

public struct StandardStreamLogHandler: LogHandler {
	public subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
		get { metadata[metadataKey] }
		set(newValue) { metadata[metadataKey] = newValue }
	}

	public var metadata: Logging.Logger.Metadata
	public var logLevel: Logging.Logger.Level

	private let stdout: StandardOutputTextStream = .stdout
	private let stderr: StandardOutputTextStream = .stderr

	private let label: String

	init(_ label: String, level: Logger.Level = .info, metadata: Logger.Metadata = [:]) {
		self.label = label
		self.logLevel = level
		self.metadata = metadata
	}

	var date: String {
		switch logLevel {
		case .trace, .debug, .notice, .warning, .error, .critical:
			"\(Date.now) "
		default:
			""
		}
	}

	var levelLabel: String {
		switch logLevel {
		case .trace:
			"[TRACE] "
		case .debug:
			"[DEBUG] "
		case .notice, .warning:
			"[~] "
		case .error:
			"[!] "
		case .critical:
			"[!!!] "
		default:
			""
		}
	}

	public func log(
		level: Logger.Level,
		message: Logger.Message,
		metadata: Logger.Metadata?,
		source: String,
		file: String,
		function: String,
		line: UInt
	) {
		let newMessage = "\(date)\(sourceInformation(file, function, line))\(levelLabel)[\(label)] \(message)\n"

		switch level {
		case .error, .critical:
			stderr.write(newMessage)
		default:
			stdout.write(newMessage)
		}
	}

	private func sourceInformation(_ file: String, _ function: String, _ line: UInt) -> String {
		switch logLevel {
		case .trace, .debug, .notice, .warning, .error, .critical:
			"[\(file):\(line) \(function)] "
		default:
			""
		}
	}
}
