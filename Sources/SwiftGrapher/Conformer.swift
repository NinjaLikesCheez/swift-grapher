import SwiftSyntax

public protocol IsTypeDeclaration {
	var declSyntax: DeclSyntaxProtocol { get }
	var qualifiedName: String { get }
	var modifiers: DeclModifierListSyntax { get }
}

extension ProtocolDeclSyntax: IsTypeDeclaration {
	public var declSyntax: DeclSyntaxProtocol { self }
}
extension ClassDeclSyntax: IsTypeDeclaration {
	public var declSyntax: DeclSyntaxProtocol { self }
}
extension StructDeclSyntax: IsTypeDeclaration {
	public var declSyntax: DeclSyntaxProtocol { self }
}
extension EnumDeclSyntax: IsTypeDeclaration {
	public var declSyntax: DeclSyntaxProtocol { self }
}
extension ActorDeclSyntax: IsTypeDeclaration {
	public var declSyntax: DeclSyntaxProtocol { self }
}
extension ExtensionDeclSyntax: IsTypeDeclaration {
	public var declSyntax: DeclSyntaxProtocol { self }
}

// public protocol HasTypeDeclaration {
// 	associatedtype IsTypeDeclaration
// 	var decl: IsTypeDeclaration { get }
// }

// public struct Class: HasTypeDeclaration {
// 	public var decl: ClassDeclSyntax
// }

// public struct Struct: HasTypeDeclaration {
// 	public var decl: StructDeclSyntax
// }

// public struct Enum: HasTypeDeclaration {
// 	public var decl: EnumDeclSyntax
// }

// public struct Actor: HasTypeDeclaration {
// 	public var decl: ActorDeclSyntax
// }

// public struct Extension: HasTypeDeclaration {
// 	public var decl: ExtensionDeclSyntax
// }

// public struct AnyTypeDeclaration: HasTypeDeclaration {
// 	public let decl: any HasTypeDeclaration

// 	init(_ decl: any HasTypeDeclaration) {
// 		self.decl = decl
// 	}
// }

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

	var declSyntax: DeclSyntaxProtocol {
		decl.declSyntax
	}
}

// public enum Conformer {
// 	case `protocol`(ProtocolDeclSyntax)
// 	case `class`(ClassDeclSyntax)
// 	case `struct`(StructDeclSyntax)
// 	case `enum`(EnumDeclSyntax)
// 	case `actor`(ActorDeclSyntax)
// 	case `extension`(ExtensionDeclSyntax)

// 	var decl: DeclSyntaxProtocol {
// 		switch self {
// 		case .protocol(let type): return type
// 		case .class(let type): return type
// 		case .struct(let type): return type
// 		case .enum(let type): return type
// 		case .actor(let type): return type
// 		case .extension(let type): return type
// 		}
// 	}

// 	var qualifiedName: String {
// 		switch self {
// 		case .protocol(let type): return type.qualifiedName
// 		case .class(let type): return type.qualifiedName
// 		case .struct(let type): return type.qualifiedName
// 		case .enum(let type): return type.qualifiedName
// 		case .actor(let type): return type.qualifiedName
// 		case .extension(let type): return type.qualifiedName
// 		}
// 	}

// 	var visibility: VisibilityModifier {
// 		let modifiers = switch self {
// 			case .protocol(let type): type.modifiers
// 			case .class(let type): type.modifiers
// 			case .struct(let type): type.modifiers
// 			case .enum(let type): type.modifiers
// 			case .actor(let type): type.modifiers
// 			case .extension(let type): type.modifiers
// 			}

// 		return modifiers.compactMap { VisibilityModifier(rawValue: $0.name.text) }.first ?? .internal
// 	}

// 	init?(decl: DeclSyntaxProtocol) {
// 		switch decl {
// 		case let type as ProtocolDeclSyntax:
// 			self = .protocol(type)
// 		case let type as ClassDeclSyntax:
// 			self = .class(type)
// 		case let type as StructDeclSyntax:
// 			self = .struct(type)
// 		case let type as EnumDeclSyntax:
// 			self = .enum(type)
// 		case let type as ActorDeclSyntax:
// 			self = .actor(type)
// 		case let type as ExtensionDeclSyntax:
// 			self = .extension(type)
// 		default:
// 			print("TypeDeclaration.init(decl:) called with non-supported decl type: \(type(of: decl)): \(decl)")
// 			return nil
// 		}
// 	}
// }
