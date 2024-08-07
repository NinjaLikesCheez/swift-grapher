import SwiftSyntax

public enum VisibilityModifier: String {
	case open
	case `package`
	case `internal`
	case `fileprivate`
	case `private`
	case `public`
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
	let conformers: [DeclSyntaxProtocol]

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

		conformers = typeManager.conformers[decl.qualifiedName] ?? []
	}
}

extension Protocol: CustomStringConvertible {
	public var description: String {
		"""
		Protocol(name: \(name),
			extensions: \(extensions.map { $0.extendedType.text }),
			inherited: \(inherited.map { $0.qualifiedName }),
			conformers: \(conformers.map { nameOfDecl($0) })
		)
		"""
	}
}
