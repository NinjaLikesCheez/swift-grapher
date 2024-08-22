import SwiftSyntax

public enum VisibilityModifier: String, Comparable, CaseIterable {
	case open
	case `public`
	case `package`
	case `internal`
	case `fileprivate`
	case `private`

	/// This is ordered in reverse so comparisons read as 'lhs is more open than rhs'
	private var comparableValue: Int {
		// Horrible
		switch self {
		case .open: 6
		case .public: 5
		case .package: 4
		case .internal: 3
		case .fileprivate: 2
		case .private: 1
		}
	}

	public static func < (lhs: Self, rhs: Self) -> Bool {
		return lhs.comparableValue < rhs.comparableValue
	}
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
