//
//  RowRapper.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 02/03/2023.
//

import Foundation

extension Row {
	/// This is a simple wrapper around sections that can be used to apply multiple properties to a section in one go
	open class Group: SectionContent<ContainerType> {
		public init(@SectionContentBuilder<ContainerType> builder: () -> SectionContentBuilder<ContainerType>.Collection) {
			super.init(items: builder().items)
		}
	}
}

extension Row {
	open class WithContainer<OtherContainerType: AnyObject>: SectionContent<ContainerType> {
		public init(_ container: OtherContainerType, @SectionContentBuilder<OtherContainerType> builder: () -> SectionContentBuilder<OtherContainerType>.Collection) {
			let items = builder().items.map { $0.adapt(to: ContainerType.self, from: container) }
			super.init(items: items)
		}
	}
}
