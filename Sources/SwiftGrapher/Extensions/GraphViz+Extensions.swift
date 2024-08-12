import Foundation
import GraphViz
import SwiftSyntax

public extension Graph {
	func write(to path: URL) throws {
		let encoder = DOTEncoder()
		let dot = encoder.encode(self)

		try dot.write(to: path, atomically: true, encoding: .utf8)
	}
}

extension Node.Shape {
	init(for decl: DeclSyntaxProtocol) {
		switch decl {
		case is ProtocolDeclSyntax:
			self = .circle
		case is StructDeclSyntax, is ClassDeclSyntax, is EnumDeclSyntax:
			self = .box
		case is ActorDeclSyntax:
			self = .diamond
		case is ExtensionDeclSyntax:
			self = .box3d
		default:
			fatalError("Called nodeShape with unsupported DeclSyntaxProtocol type: \(type(of: decl))")
		}
	}
}

extension Color {
	init(for decl: DeclSyntaxProtocol) {
		switch decl {
		case let type as ProtocolDeclSyntax:
			self = .rgb(red: 255, green: 153, blue: 255)
		default:
			self = .transparent
		}
	}
}
