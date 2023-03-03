//
//  MultiSelection.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

extension Row {
	/// Creates a list of rows that shows rows for every item in a Collection. The rows, in turn, can be selected/deselected by tapping on them. A binding
	/// to a `Set<Collection.Element>`  reflects what is selected.
	public class MultiSelection: SectionContent<ContainerType> {
		/// Creates selectable Rows that mirror the selection status of the given binding. Selected rows will have a checkmark accessory.
		public convenience init<Collection: RandomAccessCollection>(
			_ data: Collection,
			binding: TableBinding<Set<Collection.Element>>,
			@SectionContentBuilder<ContainerType> builder: (Collection.Element) -> SectionContentBuilder<ContainerType>.Collection
		) where Collection.Element: Hashable {
			self.init(data, identifiedBy: \.self, binding: binding, builder: builder)
		}
		
		/// Creates selectable Rows that mirror the selection status of the given binding. Selected rows will have a checkmark accessory.
		public init<Collection: RandomAccessCollection, ID: Hashable>(
			_ data: Collection,
			identifiedBy: KeyPath<Collection.Element, ID>,
			binding: TableBinding<Set<ID>>,
			@SectionContentBuilder<ContainerType> builder: (Collection.Element) -> SectionContentBuilder<ContainerType>.Collection
		) where Collection.Element: Hashable {
			let items = data.flatMap { element in
				let identifier = element[keyPath: identifiedBy]
				let collection = RowCollection(builder(element), id: .custom(identifier))
				collection.checked(binding.wrappedValue.contains(identifier)).onSelect { container in
					if binding.wrappedValue.contains(identifier) {
						binding.wrappedValue.remove(identifier)
					} else {
						binding.wrappedValue.insert(identifier)
					}
				}
				return collection.items
			}
			super.init(items: items)
		}
	}
}
