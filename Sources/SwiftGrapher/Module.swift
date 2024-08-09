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

	public func graphs(for graphType: GraphType) -> [Graph] {
		switch graphType {
		case .protocols:
			protocolGraphs()
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

	private func protocolGraphs() -> [Graph] {
		var graphs = [Graph]()
		let protocols = protocols()

		for protocolObject in protocols {
			var graph = Graph(directed: true)
			graph.id = protocolObject.decl.qualifiedName
			print("creating graph for: \(graph.id!)")

			guard protocolObject.visibility == .public else { continue }

			// Create a node for the root protocol object
			var root = Node(protocolObject.name)
			root.shape = Node.Shape(for: protocolObject.decl)
			root.fillColor = Color(for: protocolObject.decl)
			graph.append(root)
			print("adding root node: \(protocolObject.name)")

			func visit(conformer: Conformer, parent: Node) {
				print("visiting conformer: \(conformer.qualifiedName) for parent: \(parent.id)")
				// Visibility modifiers cannot be used with extensions that declare protocol conformances
				guard conformer.decl is ExtensionDeclSyntax || conformer.visibility == .public else { return }

				var conformerNode = Node(conformer.qualifiedName)
				conformerNode.shape = Node.Shape(for: conformer.decl)
				conformerNode.fillColor = Color(for: conformer.decl)

				let edge = Edge(from: conformerNode, to: parent, direction: .forward)
				graph.append(conformerNode)
				graph.append(edge)

				// Loop on the next set of conformers
				(typeManager.conformers[conformer.qualifiedName] ?? []).forEach { visit(conformer: $0, parent: conformerNode) }
			}

			func visit(protocol inheritedProtocol: ProtocolDeclSyntax, parent: Node) {
				guard let protocolObject = protocols.first(where: { $0.decl == inheritedProtocol }) else { return }

				print("visiting inherited protocol: \(protocolObject.name)")
				guard protocolObject.visibility == .public else { return }

				var inheritedNode = Node(protocolObject.name)
				inheritedNode.shape = Node.Shape(for: protocolObject.decl)
				inheritedNode.fillColor = Color(for: protocolObject.decl)

				// A back relationship from the inherited to inheritor
				let edge = Edge(from: parent, to: inheritedNode, direction: .forward)
				graph.append(inheritedNode)
				graph.append(edge)

				guard let nextInheritor = protocols.first(where: { $0.name == inheritedProtocol.qualifiedName }) else { return }

				nextInheritor
					.inherited
					.forEach { visit(protocol: $0, parent: inheritedNode) }

				// TODO: should we accept a Protocol for this function? Might make life a little easier
			}

			for conformer in protocolObject.conformers {
				// Visit all conformers
				visit(conformer: conformer, parent: root)

				// guard conformer.visibility == .public else { continue }

				// var conformerNode = Node(conformer.qualifiedName)
				// conformerNode.shape = Node.Shape(for: conformer.decl)
				// conformerNode.fillColor = Color(for: conformer.decl)

				// let edge = Edge(from: conformerNode, to: root, direction: .forward)
				// graph.append(conformerNode)
				// graph.append(edge)

				// // Look up any other conformers that inherit something else
				// (typeManager.conformers[conformer.qualifiedName] ?? []).forEach { visit(conformer: $0, parent: conformerNode) }
			}

			for inheritedProtocol in protocolObject.inherited {
				visit(protocol: inheritedProtocol, parent: root)
			}

			graphs.append(graph)
		}

			// For each conformer, add a node and an edge from the root node to the conformer
			// protocolObject.conformers.forEach {
			// 	guard $0.visibility == .public else { return }
			// 	var conformer = Node($0.qualifiedName)
			// 	conformer.shape = Node.Shape(for: $0.decl)
			// 	conformer.fillColor = Color(for: $0.decl)

			// 	let edge = Edge(from: conformer, to: root, direction: .forward)

			// 	subgraph.append(conformer)
			// 	subgraph.append(edge)
			// }

			// graph.append(subgraph)
		// }

		return graphs
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
			self = .box
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
