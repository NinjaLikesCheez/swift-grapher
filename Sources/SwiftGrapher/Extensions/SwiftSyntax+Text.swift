import SwiftSyntax

extension TypeSyntax {
	var text: String {
		if let type = self.as(ArrayTypeSyntax.self) {
			return "\(type.leftSquare.text)\(TypeSyntax(type).text)\(type.rightSquare.text)"
		} else if let type = self.as(AttributedTypeSyntax.self) {
			return type.baseType.text
		} else if let type = self.as(ClassRestrictionTypeSyntax.self) {
			return type.classKeyword.text
		} else if let type = self.as(CompositionTypeSyntax.self) {
			return type.elements.map { "\($0.type.text)\($0.ampersand?.text ?? "")" }.joined()
		} else if let type = self.as(DictionaryTypeSyntax.self) {
			return "\(type.leftSquare.text)\(type.key.text)\(type.colon.text) \(type.value.text)\(type.rightSquare.text)"
		} else if let type = self.as(FunctionTypeSyntax.self) {
			return "\(type.leftParen.text)\(type.parameters.map { TypeSyntax($0)!.text })\(type.rightParen.text)"
		} else if let type = self.as(IdentifierTypeSyntax.self) {
			return "\(type.name.text)\(type.genericArgumentClause?.text ?? "")"
		} else if let type = self.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
			return "\(type.wrappedType.text)\(type.exclamationMark.text)"
		} else if let type = self.as(MemberTypeSyntax.self) {
			return "\(type.name.text)"
		} else if let type = self.as(MetatypeTypeSyntax.self) {
			return "\(type.baseType.text)\(type.period.text)\(type.metatypeSpecifier.text)"
		} else if let type = self.as(MissingTypeSyntax.self) {
			return type.placeholder.text
		} else if let type = self.as(NamedOpaqueReturnTypeSyntax.self) {
			return "\(type.genericParameterClause.text)"
		} else if let type = self.as(OptionalTypeSyntax.self) {
			return "\(type.wrappedType.text)\(type.questionMark.text)"
		} else if let type = self.as(PackElementTypeSyntax.self) {
			return "\(type.eachKeyword.text) \(type.pack.text)"
		} else if let type = self.as(PackExpansionTypeSyntax.self) {
			return "\(type.repeatKeyword.text) \(type.repetitionPattern.text)"
		} else if let type = self.as(SomeOrAnyTypeSyntax.self) {
			return "\(type.someOrAnySpecifier.text) \(type.constraint.text)"
		} else if let type = self.as(SuppressedTypeSyntax.self) {
			return "\(type.withoutTilde.text)\(type.type.text)"
		} else if let type = self.as(TupleTypeSyntax.self) {
			return "\(type.leftParen.text)\(type.elements.map { $0.text })\(type.rightParen.text)"
		} else {
			fatalError("Unhandled TypeSyntax variant: \(self)")
		}
	}
}

extension GenericArgumentClauseSyntax {
	var text: String {
		"<\(self.arguments.map { "\(TypeSyntax($0.argument)!.text)\($0.trailingComma?.text ?? "")" }.joined())>"
	}
}

extension GenericParameterClauseSyntax {
	var text: String {
		let whereClause = if let clause = genericWhereClause {
			"\(clause.whereKeyword.text) \(clause.requirements.map { $0.text }.joined(separator: ","))"
		} else {
			""
		}
		return "\(leftAngle.text)\(parameters.map { $0.name })\(whereClause)\(rightAngle.text)"
	}
}

extension GenericRequirementSyntax {
	var text: String {
		switch requirement {
		case .sameTypeRequirement(let type):
			return "\(type.leftType.text) \(type.equal.text) \(type.rightType.text)"
		case .conformanceRequirement(let type):
			return "\(type.leftType.text)\(type.colon.text) \(type.rightType.text)"
		case .layoutRequirement(let type):
			// swiftlint:disable line_length
			return "\(type.type.text)\(type.colon.text) \(type.layoutSpecifier.text)\(type.leftParen?.text ?? "")\(type.size?.text ?? "")\(type.comma?.text ?? "")\(type.alignment?.text ?? "")\(type.rightParen?.text ?? "")"
			// swiftlint:enable line_length
		}
	}
}

extension TupleTypeElementSyntax {
	var text: String {
		// swiftlint:disable line_length
		"\(inoutKeyword?.text ?? "")\(firstName?.text ?? "")\(secondName?.text ?? "")\(colon?.text ?? "")\(type.text)\(ellipsis?.text ?? "")\(trailingComma?.text ?? "")"
		// swiftlint:enable line_length
	}
}
