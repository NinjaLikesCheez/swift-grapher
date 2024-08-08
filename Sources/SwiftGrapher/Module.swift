import Foundation
import SwiftParser
import SwiftSyntax
import GraphViz

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

	public enum GraphType {
		case protocols
	}

	public func graph(for graphType: GraphType) -> Graph {
		switch graphType {
		case .protocols:
			protocolGraph()
		}
	}

	private func protocols() -> [Protocol] {
		let typeDeclarationVisitor = TypeDeclarationVisitor(viewMode: .all, typeManager: typeManager)

		sources.forEach {
			typeDeclarationVisitor.walk($0)
		}

		return typeManager.protocols
			.map { Protocol(decl: $0.value, typeManager: typeManager) }
	}

	private func protocolGraph() -> Graph {
		var graph = Graph(directed: true)

		for protocolObject in protocols() {
			guard protocolObject.visibility == .public else { continue }
			var subgraph = Subgraph()

						// Create a node for the root protocol object
			var root = Node(protocolObject.name)
			root.shape = Node.Shape(for: protocolObject.decl)
			root.fillColor = Color(for: protocolObject.decl)
			subgraph.append(root)

			// For each conformer, add a node and an edge from the root node to the conformer
			protocolObject.conformers.forEach {
				guard $0.visibility == .public else { return }
				var conformer = Node($0.qualifiedName)
				conformer.shape = Node.Shape(for: $0.decl)
				conformer.fillColor = Color(for: $0.decl)

				let edge = Edge(from: conformer, to: root, direction: .forward)

				subgraph.append(conformer)
				subgraph.append(edge)
			}

			graph.append(subgraph)
		}

		return graph
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
			print("saw protocol: \(node.name)")
			typeManager.add(protocol: node)
			return super.visit(node)
		}

		override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
			print("saw extension: \(node.name)")
			typeManager.add(extension: node)
			return super.visit(node)
		}

		override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
			print("saw struct: \(node.name)")
			typeManager.add(struct: node)
			return super.visit(node)
		}

		override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
			print("saw class: \(node.name)")
			typeManager.add(class: node)
			return super.visit(node)
		}

		override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
			print("saw actor: \(node.name)")
			typeManager.add(actor: node)
			return super.visit(node)
		}

		override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
			print("saw enum: \(node.name)")
			typeManager.add(enum: node)
			return super.visit(node)
		}
	}
}

public extension Graph {
	func write(to path: URL) throws {
		let encoder = DOTEncoder()
		let dot = encoder.encode(self)

		try dot.write(to: path, atomically: true, encoding: .utf8)
	}
}

extension Node.Shape {
	init(for decl: DeclSyntaxProtocol) {
		switch decl {
		case is ProtocolDeclSyntax:
			self = .circle
		case is StructDeclSyntax, is ClassDeclSyntax, is EnumDeclSyntax:
			self = .square
		case is ActorDeclSyntax:
			self = .diamond
		case is ExtensionDeclSyntax:
			self = .box3d
		default:
			fatalError("Called nodeShape with unsupported DeclSyntaxProtocol type: \(type(of: decl))")
		}
	}
}

extension Color {
	init(for decl: DeclSyntaxProtocol) {
		switch decl {
		case is ProtocolDeclSyntax:
			self = .rgb(red: 255, green: 153, blue: 255)
		default:
			self = .transparent
		}
	}
}
