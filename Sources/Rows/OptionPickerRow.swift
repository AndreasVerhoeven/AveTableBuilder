//
//  OptionPickerRow.swift
//  Demo
//
//  Created by Andreas Verhoeven on 13/03/2023.
//

import UIKit

extension Row {
	open class OptionPicker: Row<ContainerType, UITableViewCell> {
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
			titleStyle: MenuTitleStyle = .value1,
			textProvider: @escaping (Collection.Element?) -> String
		) where Collection.Element : Equatable {
			super.init(modifying: [])
			_ = self.text(text).image(image)
			inlineOptions(options, binding: binding, titleStyle: titleStyle, textProvider: textProvider)
		}
	}
}
