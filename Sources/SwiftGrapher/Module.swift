import Foundation
import SwiftParser
import SwiftSyntax

/// Loosely represents a swift 'module' (in reality this currently means a folder...)
public struct Module {
	/// The name of the module (folder)
	public let name: String
	/// The swift files inside the module
	public let sources: [SourceFileSyntax]

	private let typeManager: TypeManager = .init()

	public enum Error: Swift.Error {
		case fileManagerError(String)
		case parsingError(String)
	}

	public init(path: URL) throws(Error) {
		name = path.lastPathComponent

		guard let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: nil) else {
			throw .fileManagerError("Failed to create directory enumerator at path: \(path.absoluteString)")
		}

		do {
			sources = try enumerator
				.compactMap { $0 as? URL }
				.filter { $0.pathExtension == "swift" }
				.map { try String(contentsOf: $0, encoding: .utf8) }
				.map { Parser.parse(source: $0) }
		} catch {
			throw .parsingError("Failed to parse with error: \(error)")
		}
	}

	/// Get all protocols in this module
	public func protocols() throws -> [Protocol] {
		let typeDeclarationVisitor = TypeDeclarationVisitor(viewMode: .all, typeManager: typeManager)

		sources.forEach {
			typeDeclarationVisitor.walk($0)
		}

		return typeManager.protocols
			.map { Protocol(decl: $0.value, typeManager: typeManager) }
	}
}

// Protocol Visitor
extension Module {
	final class TypeDeclarationVisitor: SyntaxVisitor {
		let typeManager: TypeManager

		init(viewMode: SyntaxTreeViewMode, typeManager: TypeManager) {
			self.typeManager = typeManager
			super.init(viewMode: viewMode)
		}

		override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
			typeManager.add(protocol: node)
			return super.visit(node)
		}

		override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
			typeManager.add(extension: node)
			return super.visit(node)
		}

		override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
			typeManager.add(struct: node)
			return super.visit(node)
		}

		override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
			typeManager.add(class: node)
			return super.visit(node)
		}

		override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
			typeManager.add(actor: node)
			return super.visit(node)
		}

		override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
			typeManager.add(enum: node)
			return super.visit(node)
		}
	}
}
