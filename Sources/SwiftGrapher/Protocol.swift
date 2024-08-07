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
	let extensions: Set<ExtensionDeclSyntax>

	/// Any protocols this protocol inherits
	// let inherited: [TypeDeclaration]

	/// Any protocols, classes, structs, or extensions to classes or structs that conform to this protocol
	/// Note: this has to be a string because type declarations don't conform to type syntax (i.e. an extension).
	let conformers: [TypeDeclaration]

	init(
		decl: ProtocolDeclSyntax,
		extensions: Set<ExtensionDeclSyntax>,
		conformers: [TypeDeclaration]
	) {
		self.decl = decl
		self.extensions = extensions
		// self.inherited = Set(decl.inheritanceClause?.inheritedTypes.map { $0.type } ?? [])
		self.conformers = conformers

		visibility = decl.modifiers.compactMap { VisibilityModifier(rawValue: $0.name.text) }.first ?? .internal
		name = decl.name.text
	}
}

extension Protocol: CustomStringConvertible {
	public var description: String {
		"""
		Protocol(name: \(name),
			extensions: \(extensions.map { $0.extendedType.text }),

			conformers: \(conformers.map { $0.name.text })
		)
		"""
		//inherited: \(inherited.map { $0.type.text }),
	}
}
