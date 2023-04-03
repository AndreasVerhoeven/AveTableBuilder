//
//  OptionPickerRow.swift
//  Demo
//
//  Created by Andreas Verhoeven on 13/03/2023.
//

import UIKit

extension Row {
	open class Picker<Collection: Sequence>: Row<ContainerType, UITableViewCell> {
		public init<ID: Equatable>(
			text: String? = nil,
			image: UIImage? = nil,
			options: Collection,
			identifiedBy: @escaping (Collection.Element) -> ID,
			selection: Collection.Element,
			titleStyle: MenuTitleStyle = .value1,
			textProvider: @escaping (Collection.Element) -> String,
			onChange: @escaping ( _ `self`: ContainerType, _ option: Collection.Element) -> Void
		) {
			super.init()
			_ = self.text(text).image(image)
			
			let storage = items[0].storage
			
			let selectedId: ID? = identifiedBy(selection)
			menu(title: textProvider(selection), titleStyle: titleStyle) { container in
				typealias Grouper = (Collection.Element) -> Int
				let grouper: Grouper = storage.retrieve(key: "Row.Picker.GroupingKey", default: { _ in 0 })
				var indexedGroups: [Int: [Collection.Element]] = [:]
				for option in options {
					indexedGroups[grouper(option), default: []].append(option)
				}
				
				var groups = [[Collection.Element]]()
				let keys = indexedGroups.keys.sorted(by: <)
				for key in keys {
					groups.append(indexedGroups[key] ?? [])
				}
				
				var menus = groups.map { options in
					let actions = options.map { option in
						return UIAction(title: textProvider(option), state: selectedId == identifiedBy(option) ? .on : .off, handler: { [weak container] _ in
							guard let container else { return }
							onChange(container, option)
						})
					}
					return UIMenu(title: "", options: .displayInline, children: actions)
				}
				
				if let nilElement = (Collection.Element.self as? OptionalElementProtocol.Type)?.nilValue as? Collection.Element, storage.retrieve(key: "Row.Picker.AllowSelectingNilOption", default: false) == true {
					menus.insert(UIMenu(title: "", options: .displayInline, children: [
						UIAction(title: textProvider(nilElement), state: selectedId == nil ? .on : .off, handler: { [weak container] _ in
							guard let container else { return }
							onChange(container, nilElement)
						})
					]), at: 0)
				}
				
				return UIMenu(title: "", children: menus)
			}
		}
		
		public convenience init(
			text: String? = nil,
			image: UIImage? = nil,
			options: Collection,
			selection: Collection.Element,
			titleStyle: MenuTitleStyle = .value1,
			textProvider: @escaping (Collection.Element) -> String,
			onChange: @escaping ( _ `self`: ContainerType, _ option: Collection.Element) -> Void
		) where Collection.Element: Equatable {
			self.init(text: text, image: image, options: options, identifiedBy: { $0 }, selection: selection, textProvider: textProvider, onChange: onChange)
		}
		
		
		public convenience init<ID: Equatable>(
			text: String? = nil,
			image: UIImage? = nil,
			options: Collection,
			identifiedBy: @escaping (Collection.Element) -> ID,
			binding: TableBinding<Collection.Element>,
			titleStyle: MenuTitleStyle = .value1,
			textProvider: @escaping (Collection.Element) -> String
		) {
			self.init(text: text, image: image, options: options, identifiedBy: identifiedBy, selection: binding.wrappedValue, textProvider: textProvider) { container, option in
				binding.wrappedValue = option
			}
		}
		
		public convenience init(
			text: String? = nil,
			image: UIImage? = nil,
			options: Collection,
			binding: TableBinding<Collection.Element>,
			titleStyle: MenuTitleStyle = .value1,
			textProvider: @escaping (Collection.Element) -> String
		) where Collection.Element: Equatable {
			self.init(text: text, image: image, options: options, identifiedBy: { $0 }, binding: binding, textProvider: textProvider)
		}
		
		public func grouped(by grouper: @escaping (Collection.Element) -> Int) -> Self {
			modifyRows { row in
				row.storage.store(grouper, key: "Row.Picker.GroupingKey")
			}
		}
		
		public func allowSelectingNilOption() -> Self {
			modifyRows { row in
				row.storage.store(true, key: "Row.Picker.AllowSelectingNilOption")
			}
		}
		
		public func showSeparated<S: Sequence>(_ items: S) -> Self where S.Element: Hashable, S.Element == Collection.Element {
			let set = Set(items)
			return grouped(by: { set.contains($0) ? 1 : 0 })
		}
		
		public func showSeparated(_ items: Collection.Element...) -> Self where Collection.Element: Hashable {
			showSeparated(items)
		}
	}
}


fileprivate protocol OptionalElementProtocol {
	static var nilValue: Self { get }
}

extension Optional: OptionalElementProtocol {
	static var nilValue: Self { .none }
}
