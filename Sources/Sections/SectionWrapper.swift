//
//  SectionWrapper.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

extension Section {
	/// This is a simple wrapper around sections that can be used to apply multiple properties to a section in one go
	open class Group: TableContent<ContainerType> {
		public init(@TableContentBuilder<ContainerType> builder: () -> TableContentBuilder<ContainerType>.Collection) {
			super.init(items: builder().items)
		}
	}
}

