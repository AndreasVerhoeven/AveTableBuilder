//
//  Row.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit

/// This is the most straight-forward implementation of TableContent: it represents a single section
/// with rows
open class Row<ContainerType: AnyObject, Cell: UITableViewCell>: SectionContent<ContainerType> {
	public typealias ConfigurationHandler = ( _ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void
	
	/// Creates a row with a given cell class, cell style and a configuration handler. For reuse purposes, also specify which configurable cell items
	/// you are modifying.
	public init(
		cellClass: Cell.Type = Cell.self,
		style: UITableViewCell.CellStyle = .default,
		modifying: RowConfiguration = [.manual],
		_ configuration: @escaping ConfigurationHandler
	) {
		let item = RowInfo<ContainerType>(cellClass: cellClass, style: style, modifying: modifying, configuration: configuration)
		super.init(item: item)
	}
}

extension Row {
	/// creates a row with a text and image
	public convenience init(text: String, image: UIImage? = nil, cellClass: Cell.Type = UITableViewCell.self) {
		self.init(cellClass: cellClass, modifying: [.text, .image]) { container, cell, animated in
			cell.textLabel?.setText(text, animated: animated)
			cell.imageView?.setImage(image, animated: animated)
		}
	}
	
	/// creates a row with a text,  value1 value and image
	public convenience init(text: String, value: String, image: UIImage? = nil, cellClass: Cell.Type = UITableViewCell.self) {
		self.init(cellClass: cellClass, style: .value1, modifying: [.text, .image, .detailText]) { container, cell, animated in
			cell.textLabel?.setText(text, animated: animated)
			cell.detailTextLabel?.setText(value, animated: animated)
			cell.imageView?.setImage(image, animated: animated)
		}
	}
	
	/// creates a row with a text,  subtitle value and image
	public convenience init(text: String, subtitle: String, image: UIImage? = nil, cellClass: Cell.Type = UITableViewCell.self) {
		self.init(cellClass: cellClass, style: .subtitle, modifying: [.text, .image, .detailText]) { container, cell, animated in
			cell.textLabel?.setText(text, animated: animated)
			cell.detailTextLabel?.setText(subtitle, animated: animated)
			cell.imageView?.setImage(image, animated: animated)
		}
	}
	
	/// provides a context menu for this cell
	@discardableResult public  func contextMenuProvider(_ handler: ((_ `self`: ContainerType, _ point: CGPoint, _ cell: Cell?) -> UIContextMenuConfiguration?)?) -> Self {
		guard let handler else { return self }
		items = items.map { item in
			guard item.contextMenuProvider == nil else { return item }
			var newItem = item
			newItem.contextMenuProvider = { container, point, cell in
				if let cell = cell {
					guard let cell = cell as? Cell else { return nil }
					return handler(container, point, cell)
				} else {
					return handler(container, point, nil)
				}
			}
			return newItem
		}
		return self
	}
}


// namespace for custom cell classes
public enum RowCells {
}
