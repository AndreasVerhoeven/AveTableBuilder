//
//  RowRapper.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 02/03/2023.
//

import Foundation

extension Row {
	/// This is a simple wrapper around sections that can be used to apply multiple properties to a section in one go
	class Group: SectionContent<ContainerType> {
		init(@SectionContentBuilder<ContainerType> builder: () -> SectionContentBuilder<ContainerType>.Collection) {
			super.init(items: builder().items)
		}
	}
}
