//
//  IncludeThingEditItem.swift
//  Demo
//
//  Created by Andreas Verhoeven on 22/03/2023.
//

import UIKit

class IncludeThingEditItem: TypedBuilderBaseEditItem<IncludeThingEditItem> {
	@TableState var isIncluded = false
	
	override var title: String? { "Include Item" }
	
	@BuilderType override func contents() -> BuilderType.Collection {
		Row.Switch(text: "Is Included", image: UIImage(systemName: "sun.haze"), binding: self.$isIncluded)
		if self.isIncluded == true {
			Row(text: "Thing is included", value: "Thing").accessory(.disclosureIndicator).onSelect { `self` in
				self.isIncluded = false
			}
		}
	}
}
