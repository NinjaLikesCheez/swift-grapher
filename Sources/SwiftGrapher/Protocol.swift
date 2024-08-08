import SwiftSyntax

public enum VisibilityModifier: String {
	case open
	case `package`
	case `internal`
	case `fileprivate`
	case `private`
	case `public`
}

public enum Conformer {
	case `protocol`(ProtocolDeclSyntax)
	case `class`(ClassDeclSyntax)
	case `struct`(StructDeclSyntax)
	case `enum`(EnumDeclSyntax)
	case `actor`(ActorDeclSyntax)
	case `extension`(ExtensionDeclSyntax)

	var decl: DeclSyntaxProtocol {
		switch self {
		case .protocol(let type): return type
		case .class(let type): return type
		case .struct(let type): return type
		case .enum(let type): return type
		case .actor(let type): return type
		case .extension(let type): return type
		}
	}

	var qualifiedName: String {
		switch self {
		case .protocol(let type): return type.qualifiedName
		case .class(let type): return type.qualifiedName
		case .struct(let type): return type.qualifiedName
		case .enum(let type): return type.qualifiedName
		case .actor(let type): return type.qualifiedName
		case .extension(let type): return type.qualifiedName
		}
	}

	var visibility: VisibilityModifier {
		let modifiers = switch self {
			case .protocol(let type): type.modifiers
			case .class(let type): type.modifiers
			case .struct(let type): type.modifiers
			case .enum(let type): type.modifiers
			case .actor(let type): type.modifiers
			case .extension(let type): type.modifiers
			}

		return modifiers.compactMap { VisibilityModifier(rawValue: $0.name.text) }.first ?? .internal
	}

	init?(decl: DeclSyntaxProtocol) {
		switch decl {
		case let type as ProtocolDeclSyntax:
			self = .protocol(type)
		case let type as ClassDeclSyntax:
			self = .class(type)
		case let type as StructDeclSyntax:
			self = .struct(type)
		case let type as EnumDeclSyntax:
			self = .enum(type)
		case let type as ActorDeclSyntax:
			self = .actor(type)
		case let type as ExtensionDeclSyntax:
			self = .extension(type)
		default:
			print("Conformer.init(decl:) called with non-supported decl type: \(type(of: decl)): \(decl)")
			return nil
		}
	}
}

public struct Protocol {
	let decl: ProtocolDeclSyntax
	let visibility: VisibilityModifier
	let name: String

	// Any Extensions of this protocol.
	//
	// Note:
	//  - Extensions to a protocol _cannot_ add conformance to another protocol
	//  - All conformance/inheritance to other protocols must come from the `ProtocolDeclSyntax`
	let extensions: [ExtensionDeclSyntax]

	/// Any protocols this protocol inherits
	let inherited: [ProtocolDeclSyntax]

	/// Any protocols, classes, structs, or extensions to classes or structs that conform to this protocol
	/// Note: this has to be a string because type declarations don't conform to type syntax (i.e. an extension).
	let conformers: [Conformer]

	init(
		decl: ProtocolDeclSyntax,
		typeManager: TypeManager
	) {
		self.decl = decl
		visibility = decl.modifiers.compactMap { VisibilityModifier(rawValue: $0.name.text) }.first ?? .internal
		name = decl.qualifiedName

		// Calculate which extensions and conformers are part of this protocol relationship
		extensions = typeManager.extensions { extensionDecl in
			extensionDecl.qualifiedName == decl.qualifiedName
		}

		inherited = decl
			.inheritanceClause?
			.inheritedTypes
			.compactMap { typeManager.protocols[$0.type.text] } ?? []

		conformers = typeManager
			.conformers[decl.qualifiedName]?
			.compactMap { Conformer(decl: $0) } ?? []
	}
}

extension Protocol: CustomStringConvertible {
	public var description: String {
		"""
		Protocol(name: \(name),
			extensions: \(extensions.map { $0.extendedType.text }),
			inherited: \(inherited.map { $0.qualifiedName }),
			conformers: \(conformers.map { $0.qualifiedName })
		)
		"""
	}
}
