//
//  EditItemBuilder.swift
//  Demo
//
//  Created by Andreas Verhoeven on 22/03/2023.
//

import UIKit

class EditItemBuilder {
	var items: [BaseEditItem]
	
	init(items: [BaseEditItem]) {
		self.items = items
	}
	
	@TableContentBuilder<EditItemBuilder> func build() -> TableContentBuilder<EditItemBuilder>.Collection {
		Section.Stylished {
			Section.ForEach(items, identifiedBy: \.id) { item in
				let contents = item.builderContents()
				if contents.items.isEmpty == false {
					Section(item.title) {
						contents
					}
				}
			}
		}
	}
	
	func build<ContainerType: AnyObject>() -> TableContentBuilder<ContainerType>.Collection {
		build().adapt(to: ContainerType.self, from: self)
	}
}
