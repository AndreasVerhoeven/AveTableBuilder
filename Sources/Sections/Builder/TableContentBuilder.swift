//
//  TableContentBuilder.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

/// This builds the contents of a table by collecting all sections and putting them in a `SectionCollection`.
/// Because we know the place in code of each section because of how the transforms are called, we generate
/// a unique identifier for each section.
///
/// The `SectionCollection` in turn holds a linear list of `SectionInfoWithRows`, which in
/// turn is used in `TableBuilder` to create a snapshot and configure cells.
@resultBuilder public struct TableContentBuilder<ContainerType: AnyObject> {
	public typealias ContentType = TableContent<ContainerType>
	public typealias Collection = SectionCollection<ContainerType>
	
	public static func buildExpression(_ expression: ContentType) -> Collection {
		Collection(expression, id: .empty)
	}
	
	public static func buildBlock(_ components: ContentType...) -> Collection {
		if components.count == 1 {
			return Collection(components[0], id: .empty)
		} else {
			return Collection(components)
		}
	}
	
	public static func buildOptional(_ component: Collection?) -> Collection {
		Collection(component, id: .kind(.optional))
	}
	
	public static func buildEither(first component: Collection) -> Collection {
		Collection(component, id: .kind(.eitherFirst))
	}
	
	public static func buildEither(second component: Collection) -> Collection {
		Collection(component, id: .kind(.eitherSecond))
	}
	
	public static func buildArray(_ components: [Collection]) -> Collection {
		Collection(forArray: components)
	}
	
	public static func buildLimitedAvailability(_ component: Collection) -> Collection {
		Collection(component, id: .kind(.limitedAvailability))
	}
}
