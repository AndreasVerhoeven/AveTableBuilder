//
//  OptionPickerRow.swift
//  Demo
//
//  Created by Andreas Verhoeven on 13/03/2023.
//

import UIKit

extension Row {
	class OptionPicker: Row<ContainerType, UITableViewCell> {
		init<Collection: RandomAccessCollection>(
			text: String,
			image: UIImage? = nil,
			options: Collection,
			showSeparately customOptions: Set<Collection.Element> = [],
			binding: TableBinding<Collection.Element>,
			titleStyle: MenuTitleStyle = .value1,
			textProvider: @escaping (Collection.Element) -> String
		) where Collection.Element: Hashable {
			super.init(modifying: [.text, .image]) { container, cell, animated in
				cell.textLabel?.setText(text, animated: animated)
				cell.imageView?.setImage(image, animated: animated)
			}
			inlineOptions(options, binding: binding, showSeparately: customOptions, titleStyle: titleStyle, textProvider: textProvider)
		}
		
		init<Collection: RandomAccessCollection>(
			text: String,
			image: UIImage? = nil,
			options: Collection,
			binding: TableBinding<Collection.Element?>,
			titleStyle: MenuTitleStyle = .value1,
			textProvider: @escaping (Collection.Element?) -> String
		) where Collection.Element : Equatable {
			super.init(modifying: [.text, .image]) { container, cell, animated in
				cell.textLabel?.setText(text, animated: animated)
				cell.imageView?.setImage(image, animated: animated)
			}
			inlineOptions(options, binding: binding, titleStyle: titleStyle, textProvider: textProvider)
		}
	}
}
