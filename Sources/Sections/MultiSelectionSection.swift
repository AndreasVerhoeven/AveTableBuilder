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
			
			super.init(items: section.items)
			
			items.forEach { item in
				item.sectionInfo.headerUpdaters.append { `container`, view, text, tableView, section, animated, info in
					let configuration = info.storage.retrieve(key: .multiSelectionConfiguration, as: MultiSelectionConfiguration.self) ?? .init()
					
					guard let view = view as? ButtonHaveableHeader else { return }
					if data.count <= 1 {
						view.setButton(title: nil, animated: animated, callback: nil)
					} else if binding.wrappedValue.count != data.count {
						view.setButton(title: configuration.selectAllTitle, animated: animated) {
							binding.wrappedValue = Set(data.map({ $0[keyPath: identifiedBy] }))
						}
					} else {
						view.setButton(title: configuration.deselectAllTitle, animated: animated) {
							binding.wrappedValue = Set()
						}
					}
				}
			}
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
			
			super.init(items: section.items)
			
			items.forEach { item in
				item.sectionInfo.headerUpdaters.append { `container`, view, text, tableView, section, animated, info in
					let configuration = info.storage.retrieve(key: .multiSelectionConfiguration, as: MultiSelectionConfiguration.self) ?? .init()
					
					guard let view = view as? ButtonHaveableHeader else { return }
					if data.count <= 1 {
						view.setButton(title: nil, animated: animated, callback: nil)
					} else if binding.wrappedValue.count == 0 {
						view.setButton(title: configuration.deselectAllTitle, animated: animated) {
							binding.wrappedValue = Set(data.map({ $0[keyPath: identifiedBy] }))
						}
					} else {
						view.setButton(title: configuration.selectAllTitle, animated: animated) {
							binding.wrappedValue = Set()
						}
					}
				}
			}
		}
		
		@discardableResult public func selectionButtonTitles(selectAll: String, deselectAll: String) -> Self {
			items.forEach { item in
				item.sectionInfo.storage.modify(key: .multiSelectionConfiguration, default: MultiSelectionConfiguration()) { value in
					value.selectAllTitle = selectAll
					value.deselectAllTitle = deselectAll
				}
			}
			return self
		}
	}
}

extension TableBuilderStore.Key {
	fileprivate static let multiSelectionConfiguration = Self(rawValue: "_multiSelectionConfiguration")
}

fileprivate struct MultiSelectionConfiguration {
	var selectAllTitle = "Select All"
	var deselectAllTitle = "Deselect All"
}
