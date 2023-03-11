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
	associatedtype ContainerType: AnyObject
	typealias RowInfoType = RowInfo<ContainerType>
	
	/// Modify all RowInfos by applying the given callback to each RowInfo to replace the old RowInfo.
	func modifyRows(_ callback: (RowInfoType) -> RowInfoType) -> Self
}

extension RowModifyable {	
	/// Configures
	@discardableResult public func configure<Cell: UITableViewCell>(
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
	
	@discardableResult public func preConfigure<Cell: UITableViewCell>(
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
	
	
	@discardableResult public func backgroundColor( _ color: UIColor) -> Self {
		preConfigure(modifying: [.backgroundColor]) { container, cell, animated in
			cell.backgroundColor = color
		}
	}
	
	@discardableResult public func accessory( _ accessoryType: UITableViewCell.AccessoryType) -> Self {
		preConfigure(modifying: [.accessory]) { container, cell, animated in
			cell.accessoryType = accessoryType
		}
	}
	
	@discardableResult public func editingAccessory( _ accessoryType: UITableViewCell.AccessoryType) -> Self {
		preConfigure(modifying: [.editingAccessory]) { container, cell, animated in
			cell.editingAccessoryType = accessoryType
		}
	}
	
	@discardableResult public func textFont( _ font: UIFont) -> Self {
		preConfigure(modifying: [.textFont]) { container, cell, animated in
			cell.textLabel?.font = font
		}
	}
	
	@discardableResult public func detailTextFont( _ font: UIFont) -> Self {
		preConfigure(modifying: [.detailTextFont]) { container, cell, animated in
			cell.detailTextLabel?.font = font
		}
	}
	
	@discardableResult public func textColor( _ color: UIColor) -> Self {
		preConfigure(modifying: [.textColor]) { container, cell, animated in
			cell.textLabel?.textColor = color
		}
	}
	
	@discardableResult public func detailTextColor( _ color: UIColor) -> Self {
		preConfigure(modifying: [.detailTextColor]) { container, cell, animated in
			cell.detailTextLabel?.textColor = color
		}
	}
	
	@discardableResult public func textAlignment( _ alignment: NSTextAlignment) -> Self {
		preConfigure(modifying: [.textAlignment]) { container, cell, animated in
			cell.textLabel?.textAlignment = alignment
		}
	}
	
	@discardableResult public func detailTextAlignment( _ alignment: NSTextAlignment) -> Self {
		preConfigure(modifying: [.detailTextAlignment]) { container, cell, animated in
			cell.detailTextLabel?.textAlignment = alignment
		}
	}
	
	@discardableResult public func imageTintColor( _ color: UIColor) -> Self {
		preConfigure(modifying: [.imageTintColor]) { container, cell, animated in
			cell.imageView?.tintColor = color
		}
	}
	
	@discardableResult public func tintColor( _ color: UIColor) -> Self {
		preConfigure(modifying: [.tintColor]) { container, cell, animated in
			cell.tintColor = color
		}
	}
	
	@discardableResult public func numberOfLines(_ value: Int) -> Self {
		preConfigure(modifying: [.numberOfLines]) { container, cell, animated in
			cell.textLabel?.numberOfLines = value
			cell.detailTextLabel?.numberOfLines = value
		}
	}
	
	@discardableResult public func editingStyle(_ style: UITableViewCell.EditingStyle?, handler: RowInfo<ContainerType>.OnCommitEditingCallback? = nil) -> Self {
		guard let style else { return self }
		return modifyRows { item in
			var newItem = item
			newItem.editingStyle = item.editingStyle ?? style
			if let handler {
				switch style {
					case .none:
						break
						
					case .insert:
						newItem.onCommitInsertHandlers.append(handler)
						
					case .delete:
						newItem.onCommitDeleteHandlers.append(handler)
						
					@unknown default:
						break
				}
			}
			return newItem
		}
	}
	
	@discardableResult public func onCommitInsertion(_ handler: @escaping RowInfo<ContainerType>.OnCommitEditingCallback) -> Self {
		modifyRows { item in
			var newItem = item
			newItem.onCommitInsertHandlers.append(handler)
			return newItem
		}
	}
	
	@discardableResult public func onCommitDeletion(_ handler: @escaping RowInfo<ContainerType>.OnCommitEditingCallback) -> Self {
		modifyRows { item in
			var newItem = item
			newItem.onCommitDeleteHandlers.append(handler)
			return newItem
		}
	}
	
	@discardableResult public func shouldIndentWhileEditing(_ value: Bool?) -> Self {
		guard let value else { return self }
		return modifyRows { item in
			var newItem = item
			newItem.shouldIndentWhileEditing = item.shouldIndentWhileEditing ?? value
			return newItem
		}
	}
	
	@discardableResult public func allowsHighlighting(_ value: Bool, duringEditing: Bool? = nil) -> Self {
		modifyRows { item in
			var newItem = item
			newItem.allowsHighlighting = value
			newItem.allowsHighlightingDuringEditing = newItem.allowsHighlightingDuringEditing ?? duringEditing
			return newItem
		}
	}
	
	@discardableResult public func alwaysAllowsHighlighting() -> Self {
		allowsHighlighting(true, duringEditing: true)
	}
	
	@discardableResult public func onSelect(_ handler: @escaping RowInfo<ContainerType>.SelectionHandler) -> Self {
		modifyRows { item in
			item.addingSelectionHandler(handler)
		}
	}
	
	@discardableResult public func onSelect(toggle binding: TableBinding<Bool>) -> Self {
		onSelect { container in
			binding.wrappedValue.toggle()
		}
	}
	
	@discardableResult public func onSelect<T>(set binding: TableBinding<T>, to value: T) -> Self {
		onSelect { container in
			binding.wrappedValue = value
		}
	}
	
	@discardableResult public func mirrorAccessoryDuringSelection() -> Self {
		configure(modifying: [.editingAccessory]) { container, cell, animated in
			cell.editingAccessoryType = cell.accessoryType
		}
	}
	
	@discardableResult public func checked(_ isChecked: Bool) -> Self {
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
	
	@discardableResult public func leadingSwipeActions(_ handler: RowInfo<ContainerType>.SwipeActionsProvider?) -> Self {
		guard let handler else { return self }
		return modifyRows { item in
			guard item.leadingSwipeActionsProvider == nil else { return item }
			var newItem = item
			newItem.leadingSwipeActionsProvider = handler
			return newItem
		}
	}
	
	@discardableResult public func trailingSwipeActions(_ handler: RowInfo<ContainerType>.SwipeActionsProvider?) -> Self {
		guard let handler else { return self }
		return modifyRows { item in
			guard item.trailingSwipeActionsProvider == nil else { return item }
			var newItem = item
			newItem.trailingSwipeActionsProvider = handler
			return newItem
		}
	}
	
	@discardableResult public func contextMenuProvider(_ handler: RowInfo<ContainerType>.ContextMenuProvider?) -> Self {
		guard let handler else { return self }
		return modifyRows { item in
			guard item.contextMenuProvider == nil else { return item }
			var newItem = item
			newItem.contextMenuProvider = handler
			return newItem
		}
	}
	
	@discardableResult public func noAnimatedContentChanges() -> Self {
		return modifyRows { item in
			var newItem = item
			newItem.animatedContentUpdates = false
			return newItem
		}
	}
}
