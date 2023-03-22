//
//  GroupedEditItem.swift
//  Demo
//
//  Created by Andreas Verhoeven on 22/03/2023.
//

import Foundation

class GroupedEditItem: BaseEditItem {
	let subItems: [BaseEditItem]
	
	init(subItems: [BaseEditItem]) {
		self.subItems = subItems
	}
	
	@BuilderContentsBuilder override func builderContents() -> BuilderContentsResult {
		Row.ForEach(subItems, identifiedBy: \.id) { item in
			item.builderContents()
		}
	}
}
