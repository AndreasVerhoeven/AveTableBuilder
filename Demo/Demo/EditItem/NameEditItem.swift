//
//  NameEditItem.swift
//  Demo
//
//  Created by Andreas Verhoeven on 22/03/2023.
//

import UIKit
import UIKitAnimations

class NameEditItem: TypedBuilderBaseEditItem<NameEditItem> {
	@TableState var name = ""
	@TableItemReference var nameRow
	
	override var title: String? { "Name "}
	
	static let maxLength = 3
	
	@BuilderType override func contents() -> BuilderType.Collection {
		Row.TextField(binding: self.$name, placeholder: "Name")
			.reference(self.$nameRow)
			.backgroundColor(self.name.count > Self.maxLength ? .systemRed.withAlphaComponent(0.5) : nil)
	}
	
	override init() {
		super.init()
		self.$name.onChange { oldValue, newValue in
			guard oldValue.count <= Self.maxLength && newValue.count > Self.maxLength else { return }
			self.$nameRow.scrollTo()
			self.$nameRow.cell?.shake()
		}
	}
}
