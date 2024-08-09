import SwiftSyntax

final class TypeManager {
	private(set) var protocols = [String: ProtocolDeclSyntax]()
	private(set) var structs = [String: StructDeclSyntax]()
	private(set) var classes = [String: ClassDeclSyntax]()
	private(set) var extensions = [String: [ExtensionDeclSyntax]]()
	private(set) var enums = [String: EnumDeclSyntax]()
	private(set) var actors = [String: ActorDeclSyntax]()

	private(set) var conformers = [String: [Conformer]]()

	init() {}

	private func filter<T: DeclSyntaxProtocol>(collection: [T], predicate: (T) -> Bool) -> [T] {
		collection.filter(predicate)
	}
}

extension TypeManager {
	func add(protocol decl: ProtocolDeclSyntax) {
		protocols[decl.qualifiedName] = decl
		add(inheritedTypes: decl.inheritanceClause?.inheritedTypes ?? [], to: decl)
	}

	func add(struct decl: StructDeclSyntax) {
		structs[decl.qualifiedName] = decl
		add(inheritedTypes: decl.inheritanceClause?.inheritedTypes ?? [], to: decl)
	}

	func add(class decl: ClassDeclSyntax) {
		classes[decl.qualifiedName] = decl
		add(inheritedTypes: decl.inheritanceClause?.inheritedTypes ?? [], to: decl)
	}

	func add(extension decl: ExtensionDeclSyntax) {
		extensions[decl.qualifiedName, default: []].append(decl)
		add(inheritedTypes: decl.inheritanceClause?.inheritedTypes ?? [], to: decl)
	}

	func add(enum decl: EnumDeclSyntax) {
		enums[decl.qualifiedName] = decl
		add(inheritedTypes: decl.inheritanceClause?.inheritedTypes ?? [], to: decl)
	}

	func add(actor decl: ActorDeclSyntax) {
		actors[decl.qualifiedName] = decl
		add(inheritedTypes: decl.inheritanceClause?.inheritedTypes ?? [], to: decl)
	}

	private func add(inheritedTypes: InheritedTypeListSyntax, to decl: DeclSyntaxProtocol) {
		inheritedTypes.forEach {
			guard let conformer = Conformer(decl: decl) else { return }
			conformers[$0.type.text, default: []].append(conformer)
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

	func conformers(matching predicate: (Conformer) -> Bool) -> [Conformer] {
		conformers.values.flatMap { $0 }.filter(predicate)
	}
}
