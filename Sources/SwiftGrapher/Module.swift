import Foundation
import SwiftParser
import SwiftSyntax
import GraphViz
import Logging

/// Loosely represents a swift 'module' (in reality this currently means a folder...)
public struct Module {
	/// The name of the module (folder)
	public let name: String
	/// The swift files inside the module
	public let sources: [SourceFileSyntax]

	private let typeManager: TypeManager = .init()

	private let logger: Logger = Logger(label: "Module")

	private lazy var protocols: [String: Protocol] = {
		let typeDeclarationVisitor = TypeDeclarationVisitor(viewMode: .all, typeManager: typeManager)

		sources.forEach {
			typeDeclarationVisitor.walk($0)
		}

		return typeManager.protocols
			.map { Protocol(decl: $0.value.decl, typeManager: typeManager) }
			.reduce(into: [String: Protocol]()) { partialResult, protocolObject in
				partialResult[protocolObject.typeDecl.qualifiedName] = protocolObject
			}
	}()

	public enum Error: Swift.Error {
		case fileManagerError(String)
		case parsingError(String)
	}

	public enum GraphType {
		case protocols
	}

	public init(path: URL) throws(Error) {
		name = path.lastPathComponent

		guard let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: nil) else {
			logger.error("Failed to enumerate path (\(path.path()))")
			throw .fileManagerError("Failed to enumerate path (\(path.path()))")
		}

		logger.info("loading source files")

		do {
			sources = try enumerator
				.compactMap { $0 as? URL }
				.filter { $0.pathExtension == "swift" }
				.map { try String(contentsOf: $0, encoding: .utf8) }
				.map { Parser.parse(source: $0) }
		} catch {
			logger.error("Failed to parse sources: \(error)")
			throw .parsingError("Failed to parse sources: \(error)")
		}
	}

	public mutating func graphs(for graphType: GraphType) -> [Graph] {
		switch graphType {
		case .protocols:
			protocolGraphs()
		}
	}

	private mutating func protocolGraphs() -> [Graph] {
		var graphs = [Graph]()

		for (qualifiedName, protocolObject) in protocols {
			var graph = Graph(directed: true)

			graph.id = qualifiedName
			logger.info("creating graph for: \(graph.id!)")

			// Create a node for the root protocol object
			var protocolNode = Node(qualifiedName)
			protocolNode.shape = protocolObject.typeDecl.shape
			protocolNode.fillColor = protocolObject.typeDecl.color

			graph.append(protocolNode)
			logger.debug("added 'root' protocol node: \(qualifiedName)")

			protocolObject
				.conformers
				.forEach { visit(conformer: $0, parent: protocolNode, graph: &graph) }

			protocolObject
				.inherited
				.forEach { visit(protocol: $0, parent: protocolNode, graph: &graph) }

			graphs.append(graph)
		}

		return graphs
	}

	private func visit(conformer: AnyTypeDeclaration, parent: Node, graph: inout Graph) {
		logger.info("visiting conformer: \(conformer.qualifiedName) for parent: \(parent.id)")

		var conformerNode = Node(conformer.qualifiedName)
		conformerNode.shape = conformer.shape
		conformerNode.fillColor = conformer.color

		let edge = Edge(from: conformerNode, to: parent, direction: .forward)
		graph.append(conformerNode)
		graph.append(edge)

		// Loop on the conformers to this conformer so we graph transitive conformance
		(typeManager.conformers[conformer.qualifiedName] ?? [])
			.forEach { visit(conformer: $0, parent: conformerNode, graph: &graph) }
	}

	mutating func visit(
		protocol inheritedProtocol: TypeDeclaration<ProtocolDeclSyntax>,
		parent: Node,
		graph: inout Graph
	) {
		logger.info("visiting inherited protocol: \(inheritedProtocol.qualifiedName)")

		var inheritedNode = Node(inheritedProtocol.qualifiedName)
		inheritedNode.shape = inheritedProtocol.shape
		inheritedNode.fillColor = inheritedProtocol.color

		// A back relationship from the inherited to inheritor
		let edge = Edge(from: parent, to: inheritedNode, direction: .forward)
		graph.append(inheritedNode)
		graph.append(edge)

		guard let nextInheritor = protocols[inheritedProtocol.qualifiedName] else { return }

		nextInheritor
			.inherited
			.forEach { visit(protocol: $0, parent: inheritedNode, graph: &graph) }
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
