//
//  OptionPickerRow.swift
//  Demo
//
//  Created by Andreas Verhoeven on 13/03/2023.
//

import UIKit

extension Row {
	/// A row that allows users to pick a single option from multiple options. The selected option can be `nil`, in which case it can be possible
	/// to make `nil`a valid selectable option by calling `allowSelectingNilOption()`.
	/// There are various overloads for when elements are `Equatable` or `Identifiable`.
	///
	///  Items can be grouped by calling `grouped()` or `showSeparated()`.
	///
	///  By default, items are shown as text only, but you can have more control over their appearance using `extended()`.
	open class Picker<Collection: Sequence>: Row<ContainerType, UITableViewCell> {
		
		/// Designated initializer
		///
		/// - Parameters:
		/// 	- text: the optional text to show in the row
		/// 	- image: the optional image to show in the row
		/// 	- options: the list of options users can select from
		/// 	- identifiedBy: a callback that returns a unique identifier for each option, so they can be kept apart. It's valid to use { $0 } if the options are unique and equatable
		/// 	- selection: the selected element. Can be nil if there's no selection
		/// 	- textProvider: a callback that turns the selected item into text
		/// 	- onChange: callback that will be called with the selection. If `selection` is nillable, the option passed to this callback can be `nil` as well
		public init<ID: Equatable>(
			text: String? = nil,
			image: UIImage? = .tableBuilderNone,
			options: Collection,
			identifiedBy: @escaping (Collection.Element) -> ID,
			selection: Collection.Element,
			textProvider: @escaping (Collection.Element) -> String,
			onChange: @escaping ( _ `self`: ContainerType, _ option: Collection.Element) -> Void
		) {
			super.init(modifying: [])
			_ = self.text(text, canBeOverriden: text == nil).image(image, canBeOverriden: image == nil)
			
			items[0].finalizeRowCallbacks.append { container, tableView, rowInfo in
				let storage = rowInfo.storage
				let selectedId: ID? = identifiedBy(selection)
				
				typealias OptionItemProvider = (Collection.Element) -> OptionPickerItem?
				let extendedProvider: OptionItemProvider? = storage.retrieve(key: "Row.Picker.ExtendedOptions", default: nil)
				
				let title = extendedProvider?(selection)?.title ?? textProvider(selection)
				let titleStyle = storage.retrieve(key: "Row.Picker.TitleStyle", default: MenuTitleStyle.value1)
				self.menu(title: title, titleStyle: titleStyle) { container in
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
					
					func action(for option: Collection.Element) -> UIAction {
						let isSelected = selectedId == identifiedBy(option)
						if let extendedProvider, let item = extendedProvider(option) {
							let action = UIAction(title: item.title, image: item.image, attributes: item.isEnabled == false ? [.disabled] : [], state: isSelected ? .on : .off, handler: { [weak container] _ in
								guard let container else { return }
								onChange(container, option)
							})
							if #available(iOS 15, *) {
								action.subtitle = item.subtitle
							}
							return action
						} else {
							return UIAction(title: textProvider(option), state: isSelected ? .on : .off, handler: { [weak container] _ in
								guard let container else { return }
								onChange(container, option)
							})
						}
					}
					
					var menus = groups.map { options in
						let actions = options.map { action(for: $0) }
						return UIMenu(title: "", options: .displayInline, children: actions)
					}
					
					if let nilElement = (Collection.Element.self as? OptionalElementProtocol.Type)?.nilValue as? Collection.Element,
					   storage.retrieve(key: "Row.Picker.AllowSelectingNilOption", default: false) == true {
						menus.insert(UIMenu(title: "", options: .displayInline, children: [action(for: nilElement)]), at: 0)
					}
					
					return UIMenu(title: "", children: menus)
				}
			}
		}
		
		/// Convenience init for when the options are Equatable: the options themselves will be used to identify them.
		public convenience init(
			text: String? = nil,
			image: UIImage? = .tableBuilderNone,
			options: Collection,
			selection: Collection.Element,
			textProvider: @escaping (Collection.Element) -> String,
			onChange: @escaping ( _ `self`: ContainerType, _ option: Collection.Element) -> Void
		) where Collection.Element: Equatable {
			self.init(text: text, image: image, options: options, identifiedBy: { $0 }, selection: selection, textProvider: textProvider, onChange: onChange)
		}
		
		/// Convenience init for when the options are Identifiable: the id of the options themselves will be used to identify them.
		@_disfavoredOverload public convenience init(
			text: String? = nil,
			image: UIImage? = .tableBuilderNone,
			options: Collection,
			selection: Collection.Element,
			textProvider: @escaping (Collection.Element) -> String,
			onChange: @escaping ( _ `self`: ContainerType, _ option: Collection.Element) -> Void
		) where Collection.Element: Identifiable {
			self.init(text: text, image: image, options: options, identifiedBy: { $0.id }, selection: selection, textProvider: textProvider, onChange: onChange)
		}
		
		/// Convenience init for using a binding.
		public convenience init<ID: Equatable>(
			text: String? = nil,
			image: UIImage? = .tableBuilderNone,
			options: Collection,
			identifiedBy: @escaping (Collection.Element) -> ID,
			binding: TableBinding<Collection.Element>,
			textProvider: @escaping (Collection.Element) -> String
		) {
			self.init(text: text, image: image, options: options, identifiedBy: identifiedBy, selection: binding.wrappedValue, textProvider: textProvider) { container, option in
				binding.wrappedValue = option
			}
		}
		
		/// Convenience init for using a binding when the items are Equatable.
		public convenience init(
			text: String? = nil,
			image: UIImage? = .tableBuilderNone,
			options: Collection,
			binding: TableBinding<Collection.Element>,
			textProvider: @escaping (Collection.Element) -> String
		) where Collection.Element: Equatable {
			self.init(text: text, image: image, options: options, identifiedBy: { $0 }, binding: binding, textProvider: textProvider)
		}
		
		/// Convenience init for using a binding when the items are Identifiable..
		@_disfavoredOverload public convenience init(
			text: String? = nil,
			image: UIImage? = .tableBuilderNone,
			options: Collection,
			binding: TableBinding<Collection.Element>,
			textProvider: @escaping (Collection.Element) -> String
		) where Collection.Element: Identifiable {
			self.init(text: text, image: image, options: options, identifiedBy: { $0.id }, binding: binding, textProvider: textProvider)
		}
		
		/// Use this to allow selecting `nil` as an option in the menu if the `selection` is nillable. By default, `nil` options cannot be selected.
		public func allowSelectingNilOption() -> Self {
			storage.store(true, key: "AllowSelectingNilOption")
			return self
		}
		
		/// Use this if you want to group the items visually.  The callback will be called for each element to determine in which group they belong.
		/// Return `0` for the first group, `1` for the second etc.
		public func grouped(by grouper: @escaping (Collection.Element) -> Int) -> Self {
			storage.store(grouper, key: "Row.Picker.GroupingKey")
			return self
		}
		
		/// Convenience method for grouping items: the list of items passed to this function will be shown in a separate group.
		public func showSeparated<S: Sequence>(_ items: S) -> Self where S.Element: Hashable, S.Element == Collection.Element {
			let set = Set(items)
			return grouped(by: { set.contains($0) ? 1 : 0 })
		}
		
		/// Convenience method for grouping items: the list of items passed to this function will be shown in a separate group.
		public func showSeparated(_ items: Collection.Element...) -> Self where Collection.Element: Hashable {
			showSeparated(items)
		}
		
		/// Use this if you want to show more data per item other than a title. You can return `OptionPickerItems` that show
		/// a title, subtitle (iOS 15+), image and disabled items.
		public func extended(_ provider: @escaping (Collection.Element) -> OptionPickerItem?) -> Self {
			storage.store(provider, key: "Row.Picker.ExtendedOptions")
			return self
		}
		
		/// Use this to change the way the selected item is shown. Defaults to `.value1`
		public func titleStyle(_ style: MenuTitleStyle) -> Self {
			storage.store(style, key: "Row.Picker.TitleStyle")
			return self
		}
	}
}

/// A struct that described
public struct OptionPickerItem {
	/// the title to show
	public var title: String
	/// the subtitle to show, will only be used on iOS 15+
	public var subtitle: String?
	/// the image to show
	public var image: UIImage?
	/// if false, the item will show as disabled
	public var isEnabled = true
	
	public init(title: String, subtitle: String? = nil, image: UIImage? = .tableBuilderNone, isEnabled: Bool = true) {
		self.title = title
		self.subtitle = subtitle
		self.image = image
		self.isEnabled = isEnabled
	}
}

/// internally used to support dynamic nil checks
fileprivate protocol OptionalElementProtocol {
	static var nilValue: Self { get }
}

/// internally used to support dynamic nil checks
extension Optional: OptionalElementProtocol {
	static var nilValue: Self { .none }
}
