//
//  MultiSelectionSection.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit

extension Section {
	/// Creates a section that shows rows for every item in a Collection. The rows, in turn, can be selected/deselected by tapping on them. A binding
	/// to a `Set<Collection.Element>`  reflects what is selected.
	public class MultiSelection: TableContent<ContainerType> {
		/// Creates selectable Rows that mirror the selection status of the given binding. Selected rows will have a checkmark accessory.
		public convenience init<Collection: RandomAccessCollection>(
			_ header: String? = nil,
			footer: String? = nil,
			data: Collection,
			binding: TableBinding<Set<Collection.Element>>,
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
			binding: TableBinding<Set<ID>>,
			@SectionContentBuilder<ContainerType> builder: (Collection.Element) -> SectionContentBuilder<ContainerType>.Collection
		) where Collection.Element: Hashable {
			
			let section = Section(header, footer: footer) {
				Row.MultiSelection(data, identifiedBy: identifiedBy, binding: binding, builder: builder)
			}.header(StylishedCustomHeader.self) { container, view, text, animated in
				view.label.setText(text, animated: animated)
				view.button.isHidden = (data.count <= 1)
				view.buttonCallback = {
					if binding.wrappedValue.count != data.count {
						binding.wrappedValue = Set(data.map({ $0[keyPath: identifiedBy] }))
					} else {
						binding.wrappedValue = Set()
					}
				}
				
				let buttonTitle = binding.wrappedValue.count != data.count ? "Select All" : "Deselect All"
				view.button.titleLabel?.setText(buttonTitle, animated: animated)
				view.button.setTitle(buttonTitle, for: .normal)
			}
			
			super.init(items: section.items)
		}
	}
}
