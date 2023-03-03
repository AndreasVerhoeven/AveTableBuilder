//
//  SingleSelection.swift
//  Demo
//
//  Created by Andreas Verhoeven on 03/03/2023.
//

import Foundation

extension Row {
	/// Creates a list of rows that shows rows for every item in a Collection, where only one row is selected.
	public class SingleSelection: SectionContent<ContainerType> {
		/// Creates selectable Rows that mirror the selection status of the given binding. Selected rows will have a checkmark accessory.
		public convenience init<Collection: RandomAccessCollection>(
			_ data: Collection,
			binding: TableBinding<Collection.Element>,
			@SectionContentBuilder<ContainerType> builder: (Collection.Element) -> SectionContentBuilder<ContainerType>.Collection
		) where Collection.Element: Hashable {
			self.init(data, identifiedBy: \.self, binding: binding, builder: builder)
		}
		
		/// Creates selectable Rows that mirror the selection status of the given binding. Selected rows will have a checkmark accessory.
		public init<Collection: RandomAccessCollection, ID: Hashable>(
			_ data: Collection,
			identifiedBy: KeyPath<Collection.Element, ID>,
			binding: TableBinding<ID>,
			@SectionContentBuilder<ContainerType> builder: (Collection.Element) -> SectionContentBuilder<ContainerType>.Collection
		) where Collection.Element: Hashable {
			let items = data.flatMap { element in
				let identifier = element[keyPath: identifiedBy]
				let collection = RowCollection(builder(element), id: .custom(identifier))
				collection.preConfigure(modifying: [.accessory]) { container, cell, animated in
					cell.accessoryType = binding.wrappedValue == identifier ? .checkmark : .none
				}
				return collection.items
			}
			super.init(items: items)
		}
	}
}
