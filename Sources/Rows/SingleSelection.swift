//
//  SingleSelection.swift
//  Demo
//
//  Created by Andreas Verhoeven on 03/03/2023.
//

import Foundation

extension Row {
	/// Creates a list of rows that shows rows for every item in a Collection, where only one row is selected.
	open class SingleSelection: SectionContent<ContainerType> {
		/// Creates selectable Rows that mirror the selection status of the given binding. Selected rows will have a checkmark accessory.
		public convenience init<Collection: RandomAccessCollection>(
			_ data: Collection,
			binding: TableBinding<Collection.Element>,
			@SectionContentBuilder<ContainerType> builder: (Collection.Element) -> SectionContentBuilder<ContainerType>.Collection
		) where Collection.Element: Hashable {
			self.init(data, identifiedBy: { $0 }, binding: binding, builder: builder)
		}
		
		/// Creates selectable Rows that mirror the selection status of the given binding. Selected rows will have a checkmark accessory.
		public init<Collection: RandomAccessCollection, ID: Hashable>(
			_ data: Collection,
			identifiedBy: (Collection.Element) -> ID,
			binding: TableBinding<ID>,
			@SectionContentBuilder<ContainerType> builder: (Collection.Element) -> SectionContentBuilder<ContainerType>.Collection
		) where Collection.Element: Hashable {
			let items = data.flatMap { element in
				let identifier = identifiedBy(element)
				let collection = RowCollection(builder(element), id: .custom(identifier))
				collection.preConfigure(modifying: [.accessory]) { container, cell, animated in
					cell.accessoryType = binding.wrappedValue == identifier ? .checkmark : .none
				}
				collection.onSelectSet(binding, to: identifier)
				return collection.items
			}
			super.init(items: items)
		}
	}
}
