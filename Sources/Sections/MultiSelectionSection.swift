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
	open class MultiSelection: TableContent<ContainerType> {
		private enum ButtonStatus {
			case hidden, selectAll, deselectAll
		}
		
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
			}
			
			if data.count <= 1 {
				section.store(.multiSelectionButtonStatus, value: ButtonStatus.hidden)
			} else if binding.wrappedValue.count != data.count {
				section.store(.multiSelectionButtonStatus, value: ButtonStatus.selectAll)
				section.store(.multiSelectionCallback, value: {
					binding.wrappedValue = Set(data.map({ $0[keyPath: identifiedBy] }))
				})
			} else {
				section.store(.multiSelectionButtonStatus, value: ButtonStatus.deselectAll)
				section.store(.multiSelectionCallback, value: {
					binding.wrappedValue = Set()
				})
			}
				
			super.init(items: section.items)
			
			selectionButtonTitles(selectAll: "Select All", deselectAll: "Deselect All")
		}
		
		/// Creates selectable Rows that mirror the inverted selection status of the given binding. Selected rows will have a checkmark accessory.
		public init<Collection: RandomAccessCollection, ID: Hashable>(
			_ header: String? = nil,
			footer: String? = nil,
			data: Collection,
			identifiedBy: KeyPath<Collection.Element, ID>,
			invertedBinding binding: TableBinding<Set<ID>>,
			@SectionContentBuilder<ContainerType> builder: (Collection.Element) -> SectionContentBuilder<ContainerType>.Collection
		) where Collection.Element: Hashable {
			let section = Section(header, footer: footer) {
				Row.MultiSelection(data, identifiedBy: identifiedBy, invertedBinding: binding, builder: builder)
			}
			
			if data.count <= 1 {
				section.store(.multiSelectionButtonStatus, value: ButtonStatus.hidden)
			} else if binding.wrappedValue.count == 0 {
				section.store(.multiSelectionButtonStatus, value: ButtonStatus.deselectAll)
				section.store(.multiSelectionCallback, value: {
					binding.wrappedValue = Set(data.map({ $0[keyPath: identifiedBy] }))
				})
			} else {
				section.store(.multiSelectionButtonStatus, value: ButtonStatus.selectAll)
				section.store(.multiSelectionCallback, value: {
					binding.wrappedValue = Set()
				})
			}
			
			super.init(items: section.items)
			
			selectionButtonTitles(selectAll: "Select All", deselectAll: "Deselect All")
		}
		
		@discardableResult public func selectionButtonTitles(selectAll: String, deselectAll: String) -> Self {
			items = items.map { item in
				var newItem = item
				newItem.sectionInfo.headerUpdaters.append({ container, view, text, animated in
					guard let view = view as? ButtonHaveableHeader else { return }
					let buttonStatus = Self.retrieve(.multiSelectionButtonStatus, as: ButtonStatus.self) ?? .hidden
					let callback = Self.retrieve(.multiSelectionCallback, as: (() -> Void).self) ?? {}
					
					switch buttonStatus {
						case .hidden:
							view.setButton(title: nil, animated: animated, callback: callback)
						
						case .selectAll:
							view.setButton(title: selectAll, animated: animated, callback: callback)
							
						case .deselectAll:
							view.setButton(title: deselectAll, animated: animated, callback: callback)
					}
				})
				return newItem
			}
			
			return self
		}
	}
}

extension SectionInfo.StorageKey {
	fileprivate static var multiSelectionButtonStatus: Self { Self(rawValue: "_multiSelectionButtonStatus") }
	fileprivate static var multiSelectionCallback: Self { Self(rawValue: "_multiSelectionBinding") }
}
