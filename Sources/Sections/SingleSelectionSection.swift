//
//  SingleSelectionSection.swift
//  Demo
//
//  Created by Andreas Verhoeven on 03/03/2023.
//

import Foundation

extension Section {
	/// Creates a section that shows rows for every item in a Collection. The rows, in turn, can be selected/deselected by tapping on them. A binding
	/// to a `Set<Collection.Element>`  reflects what is selected.
	public class SingleSelection: TableContent<ContainerType> {
		private enum ButtonStatus {
			case hidden, selectAll, deselectAll
		}
		
		/// Creates selectable Rows that mirror the selection status of the given binding. Only one item can be selected.
		public convenience init<Collection: RandomAccessCollection>(
			_ header: String? = nil,
			footer: String? = nil,
			data: Collection,
			binding: TableBinding<Collection.Element>,
			@SectionContentBuilder<ContainerType> builder: (Collection.Element) -> SectionContentBuilder<ContainerType>.Collection
		) where Collection.Element: Hashable {
			self.init(header, footer: footer, data: data, identifiedBy: \.self, binding: binding, builder: builder)
		}
		
		/// Creates selectable Rows that mirror the selection status of the given binding. Selected rows will have a checkmark accessory.
		public init<Collection: RandomAccessCollection, ID: Hashable>(
			_ header: String? = nil,
			footer: String? = nil,
			data: Collection,
			identifiedBy: KeyPath<Collection.Element, ID>,
			binding: TableBinding<ID>,
			@SectionContentBuilder<ContainerType> builder: (Collection.Element) -> SectionContentBuilder<ContainerType>.Collection
		) where Collection.Element: Hashable {
			let section = Section(header, footer: footer) {
				Row.SingleSelection(data, identifiedBy: identifiedBy, binding: binding, builder: builder)
			}
			super.init(items: section.items)
		}
	}
}
