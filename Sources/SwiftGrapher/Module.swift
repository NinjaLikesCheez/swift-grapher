import Foundation
import SwiftParser
import SwiftSyntax

public struct Module {
	public let name: String
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

	public func protocols() throws -> [String: Protocol] {
		let protocolNameVisitor = ProtocolNameVisitor(viewMode: .all)
		sources.forEach {
			protocolNameVisitor.walk($0)
		}

		let protocolVisitor = ProtocolVisitor(viewMode: .all, typeManager: typeManager)
		sources.forEach {
			protocolVisitor.walk($0)
		}

		var protocols = [Protocol]()

		for (name, node) in protocolVisitor.protocols {
			protocols.append(
				Protocol(
					decl: node,
					extensions: protocolVisitor.extensions[name] ?? [],
					// conformers: protocolVisitor.inheritedTypes[name].flatMap { $0.map { $0.type } } ?? []
					conformers: protocolVisitor.conformers[name] ?? []
				)
			)
		}

		for proto in protocols {
			print(proto)
		}

		// Collate the protocols and extensions to protocols
		// Collate Conformers to this protocol
		// Create protocol objects with above data

		return [:]
	}
}

extension Module {
	final class ProtocolNameVisitor: SyntaxVisitor {
		private(set) var names = Set<String>()

		override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
			names.insert(node.name.text)

			// protocols cannot be nested inside of each other:
			// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0404-nested-protocols.md
			return .skipChildren
		}
	}
}

// Protocol Visitor
extension Module {
	final class ProtocolVisitor: SyntaxVisitor {
		private(set) var protocols = [String: ProtocolDeclSyntax]()
		private(set) var structs = [String: StructDeclSyntax]()
		private(set) var classes = [String: ClassDeclSyntax]()
		private(set) var extensions = [String: Set<ExtensionDeclSyntax>]()
		private(set) var enums = [String: EnumDeclSyntax]()
		private(set) var actors = [String: ActorDeclSyntax]()

		/// Keyed by the type _inherited_ the inherited types
		private(set) var inheritedTypes = [String: Set<InheritedTypeSyntax>]()
		/// Conformed Type: Conformers of that type
		private(set) var conformers = [String: [TypeDeclaration]]()

		private let typeManager: TypeManager

		init(viewMode: SyntaxTreeViewMode, typeManager: TypeManager) {
			self.typeManager = typeManager
			super.init(viewMode: viewMode)
		}

		override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
			typeManager.add(type: .init(.protocol(node)))
			protocols[node.name.text] = node

			print("Protocol: \(node.name.text)")

			for inheritedType in node.inheritanceClause?.inheritedTypes ?? [] {
				print("inherited: \(inheritedType.type)")
				inheritedTypes[node.name.text, default: []].insert(inheritedType)
				conformers[inheritedType.type.text, default: []].append(.init(.protocol(node)))
			}

			print("------")

			return super.visit(node)
		}

		override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
			print("Extension: \(node.extendedType.text)")
			typeManager.add(type: .init(.extension(node)))
			extensions[node.extendedType.text, default: []].insert(node)

			let inheritance = node.inheritanceClause?.inheritedTypes.map { $0.type } ?? []

			if !inheritance.isEmpty {
				// We are possibly adding conformance via extension here
				print("extension to \(node.extendedType.text) adds conformance to: \(inheritance.map { $0.text })")

				for inheritor in inheritance {
					// Find the declaration for this type and add that
					conformers[inheritor.text, default: []].append(.init(.extension(node)))
				}

			}

			return super.visit(node)
		}

		override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
			// TODO: we probably want to write some kinda fully qualified name thing here....
			typeManager.add(type: .init(.struct(node)))
			structs[node.name.text] = node
			print("Struct: \(node.name.text)")
			for inheritedType in node.inheritanceClause?.inheritedTypes ?? [] {
				print("conformance to: \(inheritedType.type.text)")
				// structConformers[inheritedType.type.text, default: []].insert(node)
				conformers[inheritedType.type.text, default: []].append(.init(.struct(node)))
			}
			print("----")

			return super.visit(node)
		}

		override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
			// TODO: we probably want to write some kinda fully qualified name thing here....
			typeManager.add(type: .init(.class(node)))
			classes[node.name.text] = node
			print("Class: \(node.name.text)")
			for inheritedType in node.inheritanceClause?.inheritedTypes ?? [] {
				print("conformance to: \(inheritedType.type.text)")
				conformers[inheritedType.type.text, default: []].append(.init(.class(node)))
			}
			print("----")

			return super.visit(node)
		}

		override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
			// TODO: we probably want to write some kinda fully qualified name thing here....
			typeManager.add(type: .init(.actor(node)))
			actors[node.name.text] = node
			print("Actor: \(node.name.text)")

			for inheritedType in node.inheritanceClause?.inheritedTypes ?? [] {
				print("conformance to: \(inheritedType.type.text)")
				conformers[inheritedType.type.text, default: []].append(.init(.actor(node)))
			}
			print("----")

			return super.visit(node)
		}

		override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
			// TODO: we probably want to write some kinda fully qualified name thing here....
			typeManager.add(type: .init(.enum(node)))
			enums[node.name.text] = node
			print("Enum: \(node.name.text)")

			for inheritedType in node.inheritanceClause?.inheritedTypes ?? [] {
				print("conformance to: \(inheritedType.type.text)")
				conformers[inheritedType.type.text, default: []].append(.init(.enum(node)))
			}
			print("----")

			return super.visit(node)
		}
	}
}
