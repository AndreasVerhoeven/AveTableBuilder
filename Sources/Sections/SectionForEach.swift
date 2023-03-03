//
//  SectionForEach.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

extension Section {
	/// This creates multiple sections by iterating over a collection.
	public class ForEach: TableContent<ContainerType> {
		/// Shows the created Rows for each item in the collection. The items must be unique.
		public convenience init<Collection: RandomAccessCollection>(
			_ data: Collection,
			@TableContentBuilder<ContainerType> builder: (Collection.Element) -> TableContentBuilder<ContainerType>.Collection
		) where Collection.Element: Hashable {
			self.init(data, identifiedBy: \.self, builder: builder)
		}
		
		/// Shows the created Rows for each items in the collection, the items must be identified by a unique field
		public init<Collection: RandomAccessCollection, ID: Hashable>(
			_ data: Collection,
			identifiedBy: KeyPath<Collection.Element, ID>,
			@TableContentBuilder<ContainerType> builder: (Collection.Element) -> TableContentBuilder<ContainerType>.Collection
		) {
			let items = data.flatMap {
				element in
				builder(element).items.map { $0.appending(id: .custom(element[keyPath: identifiedBy])) }
			}
			super.init(items: items)
		}
	}
}
