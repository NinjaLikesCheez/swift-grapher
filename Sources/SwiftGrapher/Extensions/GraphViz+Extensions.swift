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

protocol GraphVizCustomizable {
	var shape: Node.Shape { get }
	var color: Color { get }
}

extension TypeDeclaration: GraphVizCustomizable {
	var color: Color {
		visibility != .public ? .rgb(red: 255, green: 102, blue: 102) : .transparent
	}

	var shape: Node.Shape { .box }
}

extension TypeDeclaration where Decl == ProtocolDeclSyntax {
	var color: Color {
		visibility == .public ? .rgb(red: 204, green: 154, blue: 255) : .rgb(red: 174, green: 129, blue: 215)
	}

	var shape: Node.Shape { .circle }
}

extension TypeDeclaration where Decl == ExtensionDeclSyntax {
	var shape: Node.Shape { .box3d }
}

extension AnyTypeDeclaration: GraphVizCustomizable {
	var shape: Node.Shape {
		switch decl {
		case is ProtocolDeclSyntax:
			.circle
		case is ExtensionDeclSyntax:
			.box3d
		default:
			.box
		}
	}

	var color: Color {
		switch decl {
		case is ProtocolDeclSyntax:
			return visibility == .public ? .rgb(red: 204, green: 154, blue: 255) : .rgb(red: 174, green: 129, blue: 215)
		case let type as ExtensionDeclSyntax:
			if type.modifiers.isEmpty {
				// Color it public since access control is likely on the individual items
				return .rgb(red: 51, green: 255, blue: 153)
			}

			return visibility == .public ? .rgb(red: 51, green: 255, blue: 153) : .rgb(red: 255, green: 102, blue: 102)
		default:
			return visibility == .public ? .rgb(red: 51, green: 255, blue: 153) : .rgb(red: 255, green: 102, blue: 102)
		}
	}
}
