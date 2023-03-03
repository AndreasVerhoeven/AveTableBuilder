//
//  RowModifyable.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit

/// Base protocol for modifying rows. By this being a protocol, we can have our modification methods
/// apply to both sections and rows.
public protocol RowModifyable {
	associatedtype ContainerType
	typealias RowInfoType = RowInfo<ContainerType>
	
	/// Modify all RowInfos by applying the given callback to each RowInfo to replace the old RowInfo.
	func modifyRows(_ callback: (RowInfoType) -> RowInfoType) -> Self
}

extension RowModifyable {
	/// Configures
	@discardableResult func configure<Cell: UITableViewCell>(
		cellOfType cellClass: UITableViewCell.Type = UITableViewCell.self,
		modifying: RowConfiguration,
		handler: @escaping ( _ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void
	) -> Self {
		modifyRows { item in
			return item.addingConfigurationHandler(modifying: modifying) { container, cell, animated in
				guard let cell = cell as? Cell else { return }
				handler(container, cell, animated)
			}
		}
	}
	
	@discardableResult func preConfigure<Cell: UITableViewCell>(
		cellOfType cellClass: UITableViewCell.Type = UITableViewCell.self,
		modifying: RowConfiguration,
		handler: @escaping ( _ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void
	) -> Self {
		modifyRows { item in
			return item.prependingConfigurationHandler(modifying: modifying) { container, cell, animated in
				guard let cell = cell as? Cell else { return }
				handler(container, cell, animated)
			}
		}
	}
	
	
	@discardableResult func backgroundColor( _ color: UIColor) -> Self {
		preConfigure(modifying: [.backgroundColor]) { container, cell, animated in
			cell.backgroundColor = color
		}
	}
	
	@discardableResult func accessory( _ accessoryType: UITableViewCell.AccessoryType) -> Self {
		preConfigure(modifying: [.accessory]) { container, cell, animated in
			cell.accessoryType = accessoryType
		}
	}
	
	@discardableResult func textFont( _ font: UIFont) -> Self {
		preConfigure(modifying: [.textFont]) { container, cell, animated in
			cell.textLabel?.font = font
		}
	}
	
	@discardableResult func detailTextFont( _ font: UIFont) -> Self {
		preConfigure(modifying: [.detailTextFont]) { container, cell, animated in
			cell.detailTextLabel?.font = font
		}
	}
	
	@discardableResult func textColor( _ color: UIColor) -> Self {
		preConfigure(modifying: [.textColor]) { container, cell, animated in
			cell.textLabel?.textColor = color
		}
	}
	
	@discardableResult func detailTextColor( _ color: UIColor) -> Self {
		preConfigure(modifying: [.detailTextColor]) { container, cell, animated in
			cell.detailTextLabel?.textColor = color
		}
	}
	
	@discardableResult func textAlignment( _ alignment: NSTextAlignment) -> Self {
		preConfigure(modifying: [.textAlignment]) { container, cell, animated in
			cell.textLabel?.textAlignment = alignment
		}
	}
	
	@discardableResult func detailTextAlignment( _ alignment: NSTextAlignment) -> Self {
		preConfigure(modifying: [.detailTextAlignment]) { container, cell, animated in
			cell.detailTextLabel?.textAlignment = alignment
		}
	}
	
	@discardableResult func imageTintColor( _ color: UIColor) -> Self {
		preConfigure(modifying: [.imageTintColor]) { container, cell, animated in
			cell.imageView?.tintColor = color
		}
	}
	
	@discardableResult func numberOfLines(_ value: Int) -> Self {
		preConfigure(modifying: [.numberOfLines]) { container, cell, animated in
			cell.textLabel?.numberOfLines = value
			cell.detailTextLabel?.numberOfLines = value
		}
	}
	
	@discardableResult func onSelect(_ handler: @escaping RowInfo<ContainerType>.SelectionHandler) -> Self {
		modifyRows { item in
			item.addingSelectionHandler(handler)
		}
	}
	
	@discardableResult func onSelect(toggle binding: TableBinding<Bool>) -> Self {
		onSelect { container in
			binding.wrappedValue.toggle()
		}
	}
	
	@discardableResult func checked(_ isChecked: Bool) -> Self {
		preConfigure(modifying: [.accessory]) { container, cell, animated in
			let newAccessoryType: UITableViewCell.AccessoryType = isChecked ? .checkmark : .none
			guard cell.accessoryType != newAccessoryType else { return }
			
			if animated == false {
				cell.accessoryType = newAccessoryType
			} else {
				if isChecked == false {
					if let button = cell.subviews.first(where: { $0 is UIButton && $0.classForCoder.description().contains("AccessoryButton") }) {
						button.performTransitionIfNeeded(animated: animated) {
							cell.accessoryType = newAccessoryType
						}
					}
				} else {
					cell.accessoryType = newAccessoryType
					if isChecked == true {
						cell.setNeedsLayout()
						cell.layoutIfNeeded()
					}
					
					if let button = cell.subviews.first(where: { $0 is UIButton && $0.classForCoder.description().contains("AccessoryButton") }) {
						button.alpha = isChecked ? 0 : 1
						UIView.performAnimationsIfNeeded(animated: animated) {
							button.alpha = isChecked ? 1 : 0
						}
					}
				}
			}
		}
	}
	
	@discardableResult func leadingSwipeActions(_ handler: RowInfo<ContainerType>.SwipeActionsProvider?) -> Self {
		guard let handler else { return self }
		return modifyRows { item in
			guard item.leadingSwipeActionsProvider == nil else { return item }
			var newItem = item
			newItem.leadingSwipeActionsProvider = handler
			return newItem
		}
	}
	
	@discardableResult func trailingSwipeActions(_ handler: RowInfo<ContainerType>.SwipeActionsProvider?) -> Self {
		guard let handler else { return self }
		return modifyRows { item in
			guard item.trailingSwipeActionsProvider == nil else { return item }
			var newItem = item
			newItem.trailingSwipeActionsProvider = handler
			return newItem
		}
	}
	
	@discardableResult func contextMenuProvider(_ handler: RowInfo<ContainerType>.ContextMenuProvider?) -> Self {
		guard let handler else { return self }
		return modifyRows { item in
			guard item.contextMenuProvider == nil else { return item }
			var newItem = item
			newItem.contextMenuProvider = handler
			return newItem
		}
	}
}
