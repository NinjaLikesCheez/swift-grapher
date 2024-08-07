import SwiftSyntax

final class TypeManager {
	private(set) var protocols = [String: ProtocolDeclSyntax]()
	private(set) var structs = [String: StructDeclSyntax]()
	private(set) var classes = [String: ClassDeclSyntax]()
	private(set) var extensions = [String: [ExtensionDeclSyntax]]()
	private(set) var enums = [String: EnumDeclSyntax]()
	private(set) var actors = [String: ActorDeclSyntax]()

	private(set) var conformers = [String: [DeclSyntaxProtocol]]()

	init() {}

	private func filter<T: DeclSyntaxProtocol>(collection: [T], predicate: (T) -> Bool) -> [T] {
		collection.filter(predicate)
	}
}

extension TypeManager {
	func add(protocol decl: ProtocolDeclSyntax) {
		protocols[decl.qualifiedName] = decl

		for inheritedType in decl.inheritanceClause?.inheritedTypes ?? [] {
			conformers[inheritedType.type.text, default: []].append(decl)
		}
	}

	func add(struct decl: StructDeclSyntax) {
		structs[decl.qualifiedName] = decl

		for inheritedType in decl.inheritanceClause?.inheritedTypes ?? [] {
			conformers[inheritedType.type.text, default: []].append(decl)
		}
	}

	func add(class decl: ClassDeclSyntax) {
		classes[decl.qualifiedName] = decl

		for inheritedType in decl.inheritanceClause?.inheritedTypes ?? [] {
			conformers[inheritedType.type.text, default: []].append(decl)
		}
	}

	func add(extension decl: ExtensionDeclSyntax) {
		extensions[decl.qualifiedName, default: []].append(decl)

		for inheritedType in decl.inheritanceClause?.inheritedTypes ?? [] {
			conformers[inheritedType.type.text, default: []].append(decl)
		}
	}

	func add(enum decl: EnumDeclSyntax) {
		enums[decl.qualifiedName] = decl

		for inheritedType in decl.inheritanceClause?.inheritedTypes ?? [] {
			conformers[inheritedType.type.text, default: []].append(decl)
		}
	}

	func add(actor decl: ActorDeclSyntax) {
		actors[decl.qualifiedName] = decl

		for inheritedType in decl.inheritanceClause?.inheritedTypes ?? [] {
			conformers[inheritedType.type.text, default: []].append(decl)
		}
	}
}

extension TypeManager {
	func protocols(matching predicate: (ProtocolDeclSyntax) -> Bool) -> [ProtocolDeclSyntax] {
		filter(collection: Array(protocols.values), predicate: predicate)
	}

	func structs(matching predicate: (StructDeclSyntax) -> Bool) -> [StructDeclSyntax] {
		filter(collection: Array(structs.values), predicate: predicate)
	}

	func classes(matching predicate: (ClassDeclSyntax) -> Bool) -> [ClassDeclSyntax] {
		filter(collection: Array(classes.values), predicate: predicate)
	}

	func enums(matching predicate: (EnumDeclSyntax) -> Bool) -> [EnumDeclSyntax] {
		filter(collection: Array(enums.values), predicate: predicate)
	}

	func extensions(matching predicate: (ExtensionDeclSyntax) -> Bool) -> [ExtensionDeclSyntax] {
		filter(collection: Array(extensions.values.flatMap { $0 }), predicate: predicate)
	}
}
