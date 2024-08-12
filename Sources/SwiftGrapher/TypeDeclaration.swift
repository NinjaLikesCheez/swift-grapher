import SwiftSyntax

public protocol IsTypeDeclaration: DeclSyntaxProtocol {
	var qualifiedName: String { get }
	var modifiers: DeclModifierListSyntax { get }
}

extension ProtocolDeclSyntax: IsTypeDeclaration {}
extension ClassDeclSyntax: IsTypeDeclaration {}
extension StructDeclSyntax: IsTypeDeclaration {}
extension EnumDeclSyntax: IsTypeDeclaration {}
extension ActorDeclSyntax: IsTypeDeclaration {}
extension ExtensionDeclSyntax: IsTypeDeclaration {}

public struct TypeDeclaration<Decl: IsTypeDeclaration> {
	let decl: Decl
	var qualifiedName: String { decl.qualifiedName }
	let visibility: VisibilityModifier

	init(_ decl: Decl) {
		self.decl = decl
		visibility = decl.modifiers.compactMap { VisibilityModifier(rawValue: $0.name.text) }.first ?? .internal
	}
}

// A type-erased version of TypeDeclaration
public struct AnyTypeDeclaration {
	let decl: IsTypeDeclaration
	var qualifiedName: String { decl.qualifiedName }
	let visibility: VisibilityModifier

	init(_ decl: IsTypeDeclaration) {
		self.decl = decl
		visibility = decl.modifiers.compactMap { VisibilityModifier(rawValue: $0.name.text) }.first ?? .internal
	}
}
