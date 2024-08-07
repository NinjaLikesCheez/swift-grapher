import SwiftSyntax

/// Return the name of a 'type' declaration (a declaration that declares a new type).
///
/// Note: this will throw a fatal error if provided a decl that is unsupported
func nameOfDecl(_ decl: DeclSyntaxProtocol) -> String {
	switch decl {
	case let type as ProtocolDeclSyntax:
		return type.name.text
	case let type as StructDeclSyntax:
		return type.name.text
	case let type as ClassDeclSyntax:
		return type.name.text
	case let type as EnumDeclSyntax:
		return type.name.text
	case let type as ActorDeclSyntax:
		return type.name.text
	case let type as ExtensionDeclSyntax:
		return type.name
	default:
		fatalError("Called nameOfDecl(_:) with unsupported DeclSyntaxProtocol")
	}
}

/// Get the fully qualified name of a declaration by walking the parent type declarations and appending their names
private func fullyQualifiedName(_ node: DeclSyntaxProtocol) -> String {
	var parent = node.parent
	let name = nameOfDecl(node)

	guard parent != nil else { return name }

	var results = [name]
	var recursionGuard = 0

	while parent != nil, recursionGuard < 15 {
		defer {
			parent = parent!.parent
			recursionGuard += 1
		}

		guard
			let decl = parent?.asProtocol(DeclSyntaxProtocol.self)
		else { continue }

		results.append(nameOfDecl(decl))
	}

	return results.reversed().joined(separator: ".")
}

extension ProtocolDeclSyntax {
	var qualifiedName: String { fullyQualifiedName(self) }
}

extension StructDeclSyntax {
	var qualifiedName: String { fullyQualifiedName(self) }
}

extension ClassDeclSyntax {
	var qualifiedName: String { fullyQualifiedName(self) }
}

extension EnumDeclSyntax {
	var qualifiedName: String { fullyQualifiedName(self) }
}

extension ActorDeclSyntax {
	var qualifiedName: String { fullyQualifiedName(self) }
}

extension ExtensionDeclSyntax {
	var qualifiedName: String { fullyQualifiedName(self) }

	var name: String {
		if let type = extendedType.as(IdentifierTypeSyntax.self) {
			return type.name.text
		} else if let type = extendedType.as(MemberTypeSyntax.self) {
			return "\(type.baseType.text)\(type.period.text)\(type.name.text)"
		}

		fatalError("Called name for an ExpressionDeclSyntax node that wasn't the expected type: \(self)")
	}
}
