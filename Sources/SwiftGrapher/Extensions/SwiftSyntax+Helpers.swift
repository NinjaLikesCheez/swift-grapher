import SwiftSyntax

// protocol TypeDecl {
// 	var name: TokenSyntax { get }
// }

// extension ProtocolDeclSyntax: TypeDecl {}
// extension StructDeclSyntax: TypeDecl {}
// extension ClassDeclSyntax: TypeDecl {}
// extension EnumDeclSyntax: TypeDecl {}
// extension ActorDeclSyntax: TypeDecl {}
// extension ExtensionDeclSyntax: TypeDecl {
// 	var name: TokenSyntax {
// 		if let type = extendedType.as(IdentifierTypeSyntax.self) {
// 			return type.name
// 		} else if let type = extendedType.as(MemberTypeSyntax.self) {
// 			return type.name
// 		}

// 		fatalError("Called name for an ExpressionDeclSyntax node that wasn't the expected type: \(self)")
// 	}
// }






struct TypeDeclaration {
	enum DeclType {
		case `protocol`(ProtocolDeclSyntax)
		case `struct`(StructDeclSyntax)
		case `class`(ClassDeclSyntax)
		case `enum`(EnumDeclSyntax)
		case actor(ActorDeclSyntax)
		case `extension`(ExtensionDeclSyntax)

		init(_ node: some DeclSyntaxProtocol) {
			switch node {
			case let type as ProtocolDeclSyntax:
				self = .protocol(type)
			case let type as StructDeclSyntax:
				self = .struct(type)
			case let type as ClassDeclSyntax:
				self = .class(type)
			case let type as EnumDeclSyntax:
				self = .enum(type)
			case let type as ActorDeclSyntax:
				self = .actor(type)
			case let type as ExtensionDeclSyntax:
				self = .extension(type)
			default:
				fatalError("Called DeclType.init(_:) with unsupported DeclSyntaxProtocol")
			}
		}

		var wrappedDecl: DeclSyntaxProtocol {
			switch self {
			case .protocol(let type): return type
			case .struct(let type): return type
			case .class(let type): return type
			case .enum(let type): return type
			case .actor(let type): return type
			case .extension(let type): return type
			}
		}

		var name: TokenSyntax {
			switch self {
			case .protocol(let type): return type.name
			case .struct(let type): return type.name
			case .class(let type): return type.name
			case .enum(let type): return type.name
			case .actor(let type): return type.name
			case .extension(let type):
				if let type = type.extendedType.as(IdentifierTypeSyntax.self) {
					return type.name
				} else if let type = type.extendedType.as(MemberTypeSyntax.self) {
					return type.name
				}

				fatalError("Called name for an ExpressionDeclSyntax node that wasn't the expected type: \(self)")
			}
		}
	}

	let declType: DeclType
	var name: TokenSyntax { declType.name }
	let fullyQualifiedName: String

	init(_ decl: DeclType) {
		declType = decl
		fullyQualifiedName = Self.fullyQualifiedName(declType)
	}

	static func fullyQualifiedName(_ node: DeclType) -> String {
		var parent = node.wrappedDecl.parent

		guard parent != nil else { return node.name.text }

		var results = [node.name.text]
		var recursionGuard = 0

		while parent != nil, recursionGuard < 15 {
			defer {
				parent = parent!.parent
				recursionGuard += 1
			}

			guard
				let decl = parent?.asProtocol(DeclSyntaxProtocol.self)
			else { continue }

			results.append(TypeDeclaration.DeclType(decl).name.text)
		}

		return results.reversed().joined(separator: ".")
	}
}

// enum TypeDeclaration {
// 	case `protocol`(ProtocolDeclSyntax)
// 	case `struct`(StructDeclSyntax)
// 	case `class`(ClassDeclSyntax)
// 	case `enum`(EnumDeclSyntax)
// 	case actor(ActorDeclSyntax)
// 	case `extension`(ExtensionDeclSyntax)

// 	init?(_ node: some DeclSyntaxProtocol) {
// 		switch node {
// 		case let type as ProtocolDeclSyntax:
// 			self = .protocol(type)
// 		case let type as StructDeclSyntax:
// 			self = .struct(type)
// 		case let type as ClassDeclSyntax:
// 			self = .class(type)
// 		case let type as EnumDeclSyntax:
// 			self = .enum(type)
// 		case let type as ActorDeclSyntax:
// 			self = .actor(type)
// 		case let type as ExtensionDeclSyntax:
// 			self = .extension(type)
// 		default:
// 			return nil
// 		}
// 	}

// 	var name: TokenSyntax {
// 		switch self {
// 		case .protocol(let type): return type.name
// 		case .struct(let type): return type.name
// 		case .class(let type): return type.name
// 		case .enum(let type): return type.name
// 		case .actor(let type): return type.name
// 		case .extension(let type):
// 			if let type = type.extendedType.as(IdentifierTypeSyntax.self) {
// 				return type.name
// 			} else if let type = type.extendedType.as(MemberTypeSyntax.self) {
// 				return type.name
// 			}

// 			fatalError("Called name for an ExpressionDeclSyntax node that wasn't the expected type: \(self)")
// 		}
// 	}

// 	private var wrappedDecl: DeclSyntaxProtocol {
// 		switch self {
// 		case .protocol(let type): return type
// 		case .struct(let type): return type
// 		case .class(let type): return type
// 		case .enum(let type): return type
// 		case .actor(let type): return type
// 		case .extension(let type): return type
// 		}
// 	}

// 	static func fullyQualifiedName(_ node: TypeDeclaration) -> String {
// 		var parent = node.wrappedDecl.parent

// 		guard parent != nil else { return node.name.text }

// 		var results = [node.name.text]
// 		var recursionGuard = 0

// 		while parent != nil, recursionGuard < 15 {
// 			defer {
// 				parent = parent!.parent
// 				recursionGuard += 1
// 			}

// 			guard
// 				let decl = parent?.asProtocol(DeclSyntaxProtocol.self),
// 				let type = TypeDeclaration(decl)
// 			else { continue }

// 			results.append(type.name.text)
// 		}

// 		return results.reversed().joined(separator: ".")
// 	}
// }

// protocol TypeDeclSyntax where Self: DeclSyntaxProtocol {
// 	var name: TokenSyntax { get }
// }

// extension ProtocolDeclSyntax: TypeDeclSyntax {}
// extension StructDeclSyntax: TypeDeclSyntax {}
// extension ClassDeclSyntax: TypeDeclSyntax {}
// extension EnumDeclSyntax: TypeDeclSyntax {}
// extension ActorDeclSyntax: TypeDeclSyntax {}

// extension ExtensionDeclSyntax: TypeDeclSyntax {
// 	var name: TokenSyntax {
// 		if let type = extendedType.as(IdentifierTypeSyntax.self) {
// 			return type.name
// 		} else if let type = extendedType.as(MemberTypeSyntax.self) {
// 			return type.name
// 		}

// 		fatalError("Called name for an ExpressionDeclSyntax node that wasn't the expected type: \(self)")
// 	}
// }
