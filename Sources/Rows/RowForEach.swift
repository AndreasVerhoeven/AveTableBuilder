//
//  RowForEach.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

extension Row {
	/// This creates multiple rows by iterating over a collection.
	open class ForEach: SectionContent<ContainerType> {
		/// Shows the created Rows for each item in the collection. The items must be unique.
		public convenience init<Collection: RandomAccessCollection>(
			_ data: Collection,
			@SectionContentBuilder<ContainerType> builder: (Collection.Element) -> SectionContentBuilder<ContainerType>.Collection
		) where Collection.Element: Hashable {
			self.init(data, identifiedBy: \.self, builder: builder)
		}
		
		/// Shows the created Rows for each items in the collection, the items must be identified by a unique field
		public init<Collection: RandomAccessCollection, ID: Hashable>(
			_ data: Collection,
			identifiedBy: KeyPath<Collection.Element, ID>,
			@SectionContentBuilder<ContainerType> builder: (Collection.Element) -> SectionContentBuilder<ContainerType>.Collection
		) {
			let items = data.flatMap {
				element in
				builder(element).items.map { $0.appending(id: .custom(element[keyPath: identifiedBy])) }
			}
			super.init(items: items)
		}
	}
}
