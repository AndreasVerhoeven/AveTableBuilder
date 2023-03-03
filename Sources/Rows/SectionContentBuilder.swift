//
//  SectionContentBuilder.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

/// This builds the contents of a section by collecting all rows and putting them in a `RowCollection`.
/// Because we know the place in code of each row because of how the transforms are called, we generate
/// a unique identifier for each section.
///
/// The `RowCollection` in turn holds a linear list of `RowInfo`, which in
/// turn is used in `TableBuilder` to create a snapshot and configure cells.
@resultBuilder public struct SectionContentBuilder<ContainerType> {
	public typealias ContentType = SectionContent<ContainerType>
	public typealias Collection = RowCollection<ContainerType>
	
	static func buildExpression(_ expression: ContentType) -> Collection {
		Collection(expression, id: .empty)
	}
	
	static func buildBlock(_ components: ContentType...) -> Collection {
		Collection(components)
	}
	
	static func buildOptional(_ component: Collection?) -> Collection {
		Collection(component, id: .kind(.optional))
	}
	
	static func buildEither(first component: Collection) -> Collection {
		Collection(component, id: .kind(.eitherFirst))
	}
	
	static func buildEither(second component: Collection) -> Collection {
		Collection(component, id: .kind(.eitherSecond))
	}
	
	static func buildArray(_ components: [Collection]) -> Collection {
		Collection(components)
	}
	
	static func buildLimitedAvailability(_ component: Collection) -> Collection {
		Collection(component, id: .kind(.limitedAvailability))
	}
}
