//
//  SectionNone.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 07/06/2023.
//

import Foundation

extension Section {
	/// Use this if you need a statement  in `switch`es that require you to have a section,
	/// without __any__ content
	class None: Section<ContainerType> {
		init() {
			super.init(contents: {})
			items.removeAll()
		}
	}
}
