//
//  RowModifyable.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit
import UIKitAnimations

/// Base protocol for modifying rows. By this being a protocol, we can have our modification methods
/// apply to both sections and rows.
public protocol RowModifyable {
	associatedtype ContainerType: AnyObject
	typealias RowInfoType = RowInfo<ContainerType>
	
	/// Modify all RowInfos by applying the given callback to each RowInfo to replace the old RowInfo.
	func modifyRows(_ callback: (RowInfoType) -> Void) -> Self
}

extension RowModifyable {
	@discardableResult public func modify<Cell: UITableViewCell>(
		_ item: RowConfiguration.Item,
		force: Bool = false,
		cellOfType cellClass: UITableViewCell.Type = UITableViewCell.self,
		handler: @escaping ( _ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void
	) -> Self {
		return addModification(for: item) { container, cell, animated, rowInfo in
			guard let cell = cell as? Cell else { return }
			handler(container, cell, animated)
		}
	}
	
	@discardableResult internal func addModification(for item: RowConfiguration.Item,
													 force: Bool = false,
													 mode: RowModificationHandlerMode = .regular,
													 handler: @escaping RowInfo<ContainerType>.ConfigurationHandler) -> Self {
		modifyRows { row in
			row.addModification(for: item, force: force, mode: mode, handler: handler)
		}
	}
	
	
	/// Configures
	@discardableResult public func configure<Cell: UITableViewCell>(
		cellOfType cellClass: UITableViewCell.Type = UITableViewCell.self,
		modifying: RowConfiguration,
		handler: @escaping ( _ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void
	) -> Self {
		modifyRows { item in
			item.addingConfigurationHandler(modifying: modifying) { container, cell, animated, row in
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
			item.prependingConfigurationHandler(modifying: modifying) { container, cell, animated, row in
				guard let cell = cell as? Cell else { return }
				handler(container, cell, animated)
			}
		}
	}
	
	@discardableResult public func backgroundColor( _ color: UIColor?) -> Self {
		return addModification(for: .backgroundColor, mode: color == nil ? .canBeOverriden : .regular) { container, cell, animated, rowInfo in
			UIView.performAnimationsIfNeeded(animated: animated) {
				cell.backgroundColor = color ?? rowInfo.defaultCellColor ?? {
					guard let tableView = SectionContent<ContainerType>.currentTableView else { return nil }
					switch tableView.style {
						case .insetGrouped, .grouped: return .secondarySystemGroupedBackground
						case .plain: return .secondarySystemBackground
						@unknown default: return .secondarySystemBackground
					}
				}()
			}
		}
	}
	
	@discardableResult public func text(_ value: String?) -> Self {
		addModification(for: .text) { container, cell, animated, rowInfo in
			cell.textLabel?.setText(value, animated: animated)
		}
	}
	
	@discardableResult public func detailText(_ value: String?) -> Self {
		addModification(for: .detailText) { container, cell, animated, rowInfo in
			cell.detailTextLabel?.setText(value, animated: animated)
		}
	}
	
	@discardableResult public func image(_ value: UIImage?) -> Self {
		addModification(for: .image) { container, cell, animated, rowInfo in
			cell.imageView?.setImage(value, animated: animated)
		}
	}
	
	@discardableResult public func accessory( _ accessoryType: UITableViewCell.AccessoryType) -> Self {
		addModification(for: .accessory) { container, cell, animated, rowInfo in
			cell.accessoryType = accessoryType
		}
	}
	
	@discardableResult public func editingAccessory( _ accessoryType: UITableViewCell.AccessoryType) -> Self {
		addModification(for: .editingAccessory) { container, cell, animated, rowInfo in
			cell.editingAccessoryType = accessoryType
		}
	}
	
	@discardableResult public func textFont( _ font: UIFont) -> Self {
		addModification(for: .textFont) { container, cell, animated, rowInfo in
			cell.textLabel?.font = font
		}
	}
	
	@discardableResult public func detailTextFont( _ font: UIFont) -> Self {
		addModification(for: .detailTextFont) { container, cell, animated, rowInfo in
			cell.textLabel?.font = font
		}
	}
	
	@discardableResult public func textColor( _ color: UIColor) -> Self {
		addModification(for: .textColor) { container, cell, animated, rowInfo in
			cell.textLabel?.textColor = color
		}
	}
	
	@discardableResult public func detailTextColor( _ color: UIColor) -> Self {
		addModification(for: .detailTextColor) { container, cell, animated, rowInfo in
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
		addModification(for: .imageTintColor) { container, cell, animated, rowInfo in
			UIView.performAnimationsIfNeeded(animated: animated) {
				cell.imageView?.tintColor = color
			}
		}
	}
	
	@discardableResult public func tintColor( _ color: UIColor) -> Self {
		addModification(for: .imageTintColor) { container, cell, animated, rowInfo in
			UIView.performAnimationsIfNeeded(animated: animated) {
				cell.tintColor = color
			}
		}
	}
	
	@discardableResult public func numberOfLines(_ value: Int) -> Self {
		preConfigure(modifying: [.numberOfLines]) { container, cell, animated in
			cell.textLabel?.numberOfLines = value
			cell.detailTextLabel?.numberOfLines = value
		}
	}
	
	@discardableResult public func editingStyle(_ style: UITableViewCell.EditingStyle?, handler: RowInfo<ContainerType>.SimpleOnCommitEditingCallback? = nil) -> Self {
		guard let style else { return self }
		return modifyRows { item in
			item.editingStyle = item.editingStyle ?? style
			if let handler {
				switch style {
					case .none:
						break
						
					case .insert:
						item.onCommitInsertHandlers.append({ container, tableView, indexPath in
							handler(container)
						})
						
					case .delete:
						item.onCommitDeleteHandlers.append({ container, tableView, indexPath in
							handler(container)
						})
						
					@unknown default:
						break
				}
			}
		}
	}
	
	@discardableResult public func onCommitInsertion(_ handler: @escaping RowInfo<ContainerType>.SimpleOnCommitEditingCallback) -> Self {
		modifyRows { item in
			item.onCommitInsertHandlers.append({ container, tableView, indexPath in
				handler(container)
			})
		}
	}
	
	@discardableResult public func onCommitDeletion(_ handler: @escaping RowInfo<ContainerType>.SimpleOnCommitEditingCallback) -> Self {
		modifyRows { item in
			item.onCommitDeleteHandlers.append({ container, tableView, indexPath in
				handler(container)
			})
		}
	}
	
	@discardableResult public func shouldIndentWhileEditing(_ value: Bool?) -> Self {
		guard let value else { return self }
		return modifyRows { item in
			item.shouldIndentWhileEditing = item.shouldIndentWhileEditing ?? value
		}
	}
	
	@discardableResult public func allowsHighlighting(_ value: Bool, duringEditing: Bool? = nil) -> Self {
		modifyRows { item in
			item.allowsHighlighting = value
			item.allowsHighlightingDuringEditing = item.allowsHighlightingDuringEditing ?? duringEditing
		}
	}
	
	@discardableResult public func alwaysAllowsHighlighting() -> Self {
		allowsHighlighting(true, duringEditing: true)
	}
	
	@discardableResult public func onSelect(_ handler: @escaping (_ `self`: ContainerType) -> Void) -> Self {
		modifyRows { item in
			item.addingSelectionHandler(handler)
		}
	}
	
	@discardableResult public func onSelectWithIndexPath(_ handler: @escaping (_ `self`: ContainerType, _ indexPath: IndexPath) -> Void) -> Self {
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
	
	@discardableResult public func leadingSwipeActions(_ handler: RowInfo<ContainerType>.SimpleSwipeActionsProvider?) -> Self {
		guard let handler else { return self }
		return modifyRows { item in
			guard item.leadingSwipeActionsProvider == nil else { return }
			item.leadingSwipeActionsProvider = { container, tableView, indexPath, row in
				handler(container)
			}
		}
	}
	
	@discardableResult public func trailingSwipeActions(_ handler: RowInfo<ContainerType>.SimpleSwipeActionsProvider?) -> Self {
		guard let handler else { return self }
		return modifyRows { item in
			guard item.trailingSwipeActionsProvider == nil else { return }
			item.trailingSwipeActionsProvider = { container, tableView, indexPath, row in
				handler(container)
			}
		}
	}
	
	@discardableResult public func contextMenuProvider(_ handler: RowInfo<ContainerType>.SimpleContextMenuProvider?) -> Self {
		guard let handler else { return self }
		return modifyRows { item in
			guard item.contextMenuProvider == nil else { return }
			item.contextMenuProvider = { container, point, cell, tableView, indexPath, row in
				handler(container, point, cell)
			}
		}
	}
	
	@discardableResult public func noAnimatedContentChanges() -> Self {
		return modifyRows { item in
			item.animatedContentUpdates = false
		}
	}
	
	@discardableResult public func onBuild(callback: () -> Void) -> Self {
		callback()
		return self
	}
}
