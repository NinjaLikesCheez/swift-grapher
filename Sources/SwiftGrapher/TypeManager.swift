import SwiftSyntax
import Logging

final class TypeManager {
	private(set) var protocols = [String: TypeDeclaration<ProtocolDeclSyntax>]()
	private(set) var structs = [String: TypeDeclaration<StructDeclSyntax>]()
	private(set) var classes = [String: TypeDeclaration<ClassDeclSyntax>]()
	private(set) var extensions = [String: [TypeDeclaration<ExtensionDeclSyntax>]]()
	private(set) var enums = [String: TypeDeclaration<EnumDeclSyntax>]()
	private(set) var actors = [String: TypeDeclaration<ActorDeclSyntax>]()

	private(set) var conformers = [String: [AnyTypeDeclaration]]()

	private let logger = Logger(label: "TypeManager")

	init() {}

	private func filter<T: DeclSyntaxProtocol>(collection: [T], predicate: (T) -> Bool) -> [T] {
		collection.filter(predicate)
	}
}

extension TypeManager {
	func add(protocol decl: ProtocolDeclSyntax) {
		let name = decl.qualifiedName
		logger.debug("saw protocol: \(name)")

		protocols[name] = .init(decl)
		add(inheritedTypes: decl.inheritanceClause?.inheritedTypes ?? [], to: decl)
	}

	func add(struct decl: StructDeclSyntax) {
		let name = decl.qualifiedName
		logger.debug("saw struct: \(name)")

		structs[decl.qualifiedName] = .init(decl)
		add(inheritedTypes: decl.inheritanceClause?.inheritedTypes ?? [], to: decl)
	}

	func add(class decl: ClassDeclSyntax) {
		let name = decl.qualifiedName
		logger.debug("saw class: \(name)")

		classes[decl.qualifiedName] = .init(decl)
		add(inheritedTypes: decl.inheritanceClause?.inheritedTypes ?? [], to: decl)
	}

	func add(extension decl: ExtensionDeclSyntax) {
		let name = decl.qualifiedName
		logger.debug("saw extension to: \(name)")

		extensions[decl.qualifiedName, default: []].append(.init(decl))
		add(inheritedTypes: decl.inheritanceClause?.inheritedTypes ?? [], to: decl)
	}

	func add(enum decl: EnumDeclSyntax) {
		let name = decl.qualifiedName
		logger.debug("saw enum: \(name)")

		enums[decl.qualifiedName] = .init(decl)
		add(inheritedTypes: decl.inheritanceClause?.inheritedTypes ?? [], to: decl)
	}

	func add(actor decl: ActorDeclSyntax) {
		let name = decl.qualifiedName
		logger.debug("saw actor: \(name)")

		actors[decl.qualifiedName] = .init(decl)
		add(inheritedTypes: decl.inheritanceClause?.inheritedTypes ?? [], to: decl)
	}

	private func add(inheritedTypes: InheritedTypeListSyntax, to decl: DeclSyntaxProtocol) {
		var names = [String]()

		inheritedTypes
			.forEach {
				guard let declaration = decl as? IsTypeDeclaration else { return }
				conformers[$0.type.text, default: []].append(.init(declaration))
				names.append($0.type.text)
			}

		if !names.isEmpty {
			logger.debug("saw inherited types: \(names.joined(separator: " "))")
		}
	}
}

extension TypeManager {
	// func protocols(matching predicate: (ProtocolDeclSyntax) -> Bool) -> [ProtocolDeclSyntax] {
	// 	filter(collection: Array(protocols.values), predicate: predicate)
	// }

	// func structs(matching predicate: (StructDeclSyntax) -> Bool) -> [StructDeclSyntax] {
	// 	filter(collection: Array(structs.values), predicate: predicate)
	// }

	// func classes(matching predicate: (ClassDeclSyntax) -> Bool) -> [ClassDeclSyntax] {
	// 	filter(collection: Array(classes.values), predicate: predicate)
	// }

	// func enums(matching predicate: (EnumDeclSyntax) -> Bool) -> [EnumDeclSyntax] {
	// 	filter(collection: Array(enums.values), predicate: predicate)
	// }

	// func extensions(matching predicate: (ExtensionDeclSyntax) -> Bool) -> [ExtensionDeclSyntax] {
	// 	filter(collection: Array(extensions.values.flatMap { $0 }), predicate: predicate)
	// }

	func conformers(matching predicate: (AnyTypeDeclaration) -> Bool) -> [AnyTypeDeclaration] {
		conformers.values.flatMap { $0 }.filter(predicate)
	}
}
