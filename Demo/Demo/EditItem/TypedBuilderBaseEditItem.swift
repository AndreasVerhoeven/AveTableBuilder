//
//  TypedBuilderBaseEditItem.swift
//  Demo
//
//  Created by Andreas Verhoeven on 22/03/2023.
//

import Foundation

class TypedBuilderBaseEditItem<ContainerType: AnyObject>: BaseEditItem {
	typealias BuilderType = SectionContentBuilder<ContainerType>
	
	var container: ContainerType { self as! ContainerType }
	@BuilderType func contents() -> BuilderType.Collection {}
	
	// MARK: - BaseEditItem
	override func builderContents() -> BuilderContentsResult {
		contents().adapt(to: EditItemBuilder.self, from: container)
	}
}
