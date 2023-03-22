//
//  BaseEditItem.swift
//  Demo
//
//  Created by Andreas Verhoeven on 22/03/2023.
//

import UIKit


class BaseEditItem {
	typealias BuilderContentsBuilder = SectionContentBuilder<EditItemBuilder>
	typealias BuilderContentsResult = BuilderContentsBuilder.Collection
	
	var title: String? { nil }
	var id: String { String(describing: self) }
	func builderContents() -> BuilderContentsResult {
		.init(items: [])
	}
}
