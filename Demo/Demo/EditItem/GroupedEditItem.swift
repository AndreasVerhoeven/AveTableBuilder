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
		for item in subItems {
			item.builderContents().identified(by: item.id)
		}
	}
}
