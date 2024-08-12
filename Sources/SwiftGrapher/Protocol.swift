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
	let typeDecl: TypeDeclaration<ProtocolDeclSyntax>

	// Any Extensions of this protocol.
	//
	// Note:
	//  - Extensions to a protocol _cannot_ add conformance to another protocol
	//  - All conformance/inheritance to other protocols must come from the `ProtocolDeclSyntax`
	let extensions: [TypeDeclaration<ExtensionDeclSyntax>]

	/// Any protocols this protocol inherits
	let inherited: [TypeDeclaration<ProtocolDeclSyntax>]

	/// Any protocols, classes, structs, or extensions to classes or structs that conform to this protocol
	let conformers: [AnyTypeDeclaration]

	init(
		decl: ProtocolDeclSyntax,
		typeManager: TypeManager
	) {
		self.typeDecl = .init(decl)

		extensions = typeManager.extensions[decl.qualifiedName] ?? []

		inherited = decl
			.inheritanceClause?
			.inheritedTypes
			.compactMap { typeManager.protocols[$0.type.text] } ?? []

		conformers = typeManager
			.conformers[decl.qualifiedName] ?? []
	}
}

extension Protocol: CustomStringConvertible {
	public var description: String {
		"""
		Protocol(name: \(typeDecl.qualifiedName),
			extensions: \(extensions.map { $0.decl.extendedType.text }),
			inherited: \(inherited.map { $0.qualifiedName }),
			conformers: \(conformers.map { $0.qualifiedName })
		)
		"""
	}
}
