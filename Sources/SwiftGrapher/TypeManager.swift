import SwiftSyntax

final class TypeManager {
	private(set) var types = [String: TypeDeclaration]()

	init() {}

	func add(type: TypeDeclaration) {
		types[type.fullyQualifiedName] = type
	}

	// TODO: look into Swift Syntax's struct vs protocol arguments and see if we can subtype and cast here...
	func extensions(matching predicate: (TypeDeclaration) -> Bool) -> [TypeDeclaration] {
		types
			.values
			.filter {
				return switch $0.declType {
				case .extension: true
				default: false
				}
			}
			.filter(predicate)
	}
}
