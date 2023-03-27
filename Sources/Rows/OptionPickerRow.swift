//
//  OptionPickerRow.swift
//  Demo
//
//  Created by Andreas Verhoeven on 13/03/2023.
//

import UIKit

extension Row {
	open class OptionPicker: Row<ContainerType, UITableViewCell> {
		public init<Collection: RandomAccessCollection, ID: Hashable>(
			text: String,
			image: UIImage?,
			options: Collection,
			identifiedBy: @escaping (Collection.Element) -> ID,
			binding: TableBinding<ID>,
			titleStyle: MenuTitleStyle = .value1,
			textProvider: @escaping (Collection.Element) -> String
		) {
			super.init(modifying: [])
			_ = self.text(text).image(image)
			let currentItem = options.first { identifiedBy($0) == binding.wrappedValue }
			let title = currentItem.flatMap(textProvider)
			menu(title: title, titleStyle: titleStyle) { container in
				let actions = options.map { option in
					let identifier = identifiedBy(option)
					let isSelected = identifier == binding.wrappedValue
					return UIAction(title: textProvider(option), state: isSelected ? .on : .off) { _ in
						binding.wrappedValue = identifier
					}
				}
				return UIMenu(title: "", children: actions)
			}
		}
		
		
		public init<Collection: RandomAccessCollection>(
			text: String,
			image: UIImage? = nil,
			options: Collection,
			showSeparately customOptions: Set<Collection.Element> = [],
			binding: TableBinding<Collection.Element>,
			titleStyle: MenuTitleStyle = .value1,
			textProvider: @escaping (Collection.Element) -> String
		) where Collection.Element: Hashable {
			super.init(modifying: [])
			_ = self.text(text).image(image)
			inlineOptions(options, binding: binding, showSeparately: customOptions, titleStyle: titleStyle, textProvider: textProvider)
		}
		
		public init<Collection: RandomAccessCollection>(
			text: String,
			image: UIImage? = nil,
			options: Collection,
			binding: TableBinding<Collection.Element?>,
			allowsSelectingNone: Bool = true,
			titleStyle: MenuTitleStyle = .value1,
			textProvider: @escaping (Collection.Element?) -> String
		) where Collection.Element : Equatable {
			super.init(modifying: [])
			_ = self.text(text).image(image)
			inlineOptions(options, binding: binding, allowsSelectingNone: allowsSelectingNone, titleStyle: titleStyle, textProvider: textProvider)
		}
	}
}
