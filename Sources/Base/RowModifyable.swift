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
	
	@discardableResult public func text(_ value: String?, canBeOverriden: Bool = false) -> Self {
		addModification(for: .text, mode: canBeOverriden ? .canBeOverriden : .regular) { container, cell, animated, rowInfo in
			cell.textLabel?.setText(value, animated: animated)
		}
	}
	
	@discardableResult public func detailText(_ value: String?) -> Self {
		addModification(for: .detailText) { container, cell, animated, rowInfo in
			cell.detailTextLabel?.setText(value, animated: animated)
		}
	}
	
	@discardableResult public func textAlpha(_ value: CGFloat) -> Self {
		addModification(for: .textAlpha) { container, cell, animated, rowInfo in
			UIView.performAnimationsIfNeeded(animated: animated) {
				cell.textLabel?.alpha = value
			}
		}
	}
	
	@discardableResult public func detailTextAlpha(_ value: CGFloat) -> Self {
		addModification(for: .detailTextAlpha) { container, cell, animated, rowInfo in
			UIView.performAnimationsIfNeeded(animated: animated) {
				cell.detailTextLabel?.alpha = value
			}
		}
	}
	
	@discardableResult public func image(_ value: UIImage?, canBeOverriden: Bool = false) -> Self {
		guard value !== UIImage.tableBuilderNone else { return self }
		
		return addModification(for: .image, mode: canBeOverriden ? .canBeOverriden : .regular) { container, cell, animated, rowInfo in
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
			cell.detailTextLabel?.font = font
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
	
	/// sets the cells image tint color
	@discardableResult public func imageTintColor( _ color: UIColor) -> Self {
		addModification(for: .imageTintColor) { container, cell, animated, rowInfo in
			UIView.performAnimationsIfNeeded(animated: animated) {
				cell.imageView?.tintColor = color
			}
		}
	}
	
	/// Sets the cells tint color
	@discardableResult public func tintColor( _ color: UIColor) -> Self {
		addModification(for: .imageTintColor) { container, cell, animated, rowInfo in
			UIView.performAnimationsIfNeeded(animated: animated) {
				cell.tintColor = color
			}
		}
	}
	
	/// Sets the number of lines for the text and detail text labels
	@discardableResult public func numberOfLines(_ value: Int) -> Self {
		preConfigure(modifying: [.numberOfLines]) { container, cell, animated in
			cell.textLabel?.numberOfLines = value
			cell.detailTextLabel?.numberOfLines = value
		}
	}
	
	/// Will set the editing style for each row and register a callback when a row is commited during editing
	@discardableResult public func editingStyle(_ style: UITableViewCell.EditingStyle?, handler: RowInfo<ContainerType>.SimpleOnCommitEditingCallback? = nil) -> Self {
		guard let style else { return self }
		return modifyRows { item in
			item.editingStyle = item.editingStyle ?? style
			if let handler {
				switch style {
					case .none:
						break
						
					case .insert:
						item.onCommitInsertHandlers.append({ container, tableView, indexPath, row in
							handler(container)
						})
						
					case .delete:
						item.onCommitDeleteHandlers.append({ container, tableView, indexPath, row in
							handler(container)
						})
						
					@unknown default:
						break
				}
			}
		}
	}
	
	/// Will call a callback when the row is comitted for insertion during editing
	@discardableResult public func onCommitInsertion(_ handler: @escaping RowInfo<ContainerType>.SimpleOnCommitEditingCallback) -> Self {
		modifyRows { item in
			item.onCommitInsertHandlers.append({ container, tableView, indexPath, row in
				handler(container)
			})
		}
	}
	
	/// Will call a callback when the row is comitted for deletion during editing
	@discardableResult public func onCommitDeletion(_ handler: @escaping RowInfo<ContainerType>.SimpleOnCommitEditingCallback) -> Self {
		modifyRows { item in
			item.onCommitDeleteHandlers.append({ container, tableView, indexPath, row in
				handler(container)
			})
		}
	}
	
	/// Sets if the row should be indented when editing
	@discardableResult public func shouldIndentWhileEditing(_ value: Bool?) -> Self {
		guard let value else { return self }
		return modifyRows { item in
			item.shouldIndentWhileEditing = item.shouldIndentWhileEditing ?? value
		}
	}
	
	/// Sets if we allow highligting a row, independent of selection callbacks. Also for during editing, if set.
	@discardableResult public func allowsHighlighting(_ value: Bool, duringEditing: Bool? = nil) -> Self {
		modifyRows { item in
			item.allowsHighlighting = value
			item.allowsHighlightingDuringEditing = item.allowsHighlightingDuringEditing ?? duringEditing
		}
	}
	
	/// Allows highlighting the row, even if no selection handlers AND during editing
	@discardableResult public func alwaysAllowsHighlighting() -> Self {
		allowsHighlighting(true, duringEditing: true)
	}
	
	/// Will call a callback whern the row is selected
	@discardableResult public func onSelect(_ handler: @escaping (_ `self`: ContainerType) -> Void) -> Self {
		modifyRows { item in
			item.addingSelectionHandler(handler)
		}
	}
	
	/// Will call a callback with the given index path if the row is selected
	@discardableResult public func onSelectWithIndexPath(_ handler: @escaping (_ `self`: ContainerType, _ indexPath: IndexPath) -> Void) -> Self {
		modifyRows { item in
			item.addingSelectionHandler(handler)
		}
	}
	
	/// Will toggle a boolean binding between true/false if the row is selected
	@discardableResult public func onSelectToggle(_ binding: TableBinding<Bool>) -> Self {
		onSelect { container in
			binding.wrappedValue.toggle()
		}
	}
	
	/// Will update a binding to a given value when the row is selected
	@discardableResult public func onSelectSet<T>(_ binding: TableBinding<T>, to value: T) -> Self {
		onSelect { container in
			binding.wrappedValue = value
		}
	}
	
	/// Ensures that `editingAccessoryType == accessoryType` for eac hrow
	@discardableResult public func mirrorAccessoryDuringSelection() -> Self {
		configure(modifying: [.editingAccessory]) { container, cell, animated in
			cell.editingAccessoryType = cell.accessoryType
		}
	}
	
	/// Checks each row if true, uncheck if false.
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
	
	/// Adds leading swipe actions to each row
	@discardableResult public func leadingSwipeActions(_ handler: RowInfo<ContainerType>.SimpleSwipeActionsProvider?) -> Self {
		guard let handler else { return self }
		return modifyRows { item in
			guard item.leadingSwipeActionsProvider == nil else { return }
			item.leadingSwipeActionsProvider = { container, tableView, indexPath, row in
				handler(container)
			}
		}
	}
	
	/// Adds trailing swipe actions to each row
	@discardableResult public func trailingSwipeActions(_ handler: RowInfo<ContainerType>.SimpleSwipeActionsProvider?) -> Self {
		guard let handler else { return self }
		return modifyRows { item in
			guard item.trailingSwipeActionsProvider == nil else { return }
			item.trailingSwipeActionsProvider = { container, tableView, indexPath, row in
				handler(container)
			}
		}
	}
	
	/// Adds a context menu via a provider to each row
	@discardableResult public func contextMenuProvider(_ handler: RowInfo<ContainerType>.SimpleContextMenuProvider?) -> Self {
		guard let handler else { return self }
		return modifyRows { item in
			guard item.contextMenuProvider == nil else { return }
			item.contextMenuProvider = { container, point, cell, tableView, indexPath, row in
				handler(container, point, cell)
			}
		}
	}
	
	/// Updates to the cell contents will always be with `animated: false`
	@discardableResult public func noAnimatedContentChanges() -> Self {
		return modifyRows { item in
			item.animatedContentUpdates = false
		}
	}
	
	/// Called when this item is build. E.g. (directly)
	@discardableResult public func onBuild(callback: () -> Void) -> Self {
		callback()
		return self
	}
	
	/// Replaces the accessoryView with an anmating ActivityIndicatorView if true
	@discardableResult public func activityIndicator(show: Bool) -> Self {
		modifyRows { item in
			item.prependingConfigurationHandler(modifying: [.accessoryView]) { container, cell, animated, row in
				if show == true {
					let spinner = (cell.accessoryView as? UIActivityIndicatorView) ?? UIActivityIndicatorView(style: .medium)
					spinner.startAnimating()
					cell.accessoryView = spinner
				} else if row.modificationHandlers[.accessoryView] == nil {
					cell.accessoryView = nil
				}
			}
		}
	}
	
	/// Makes all rows be statically instantiated: e.g. not reused.
	@discardableResult public func makeStatic() -> Self {
		modifyRows { item in
			item.forceStaticCell = true
			item.reuseIdentifierShouldIncludeId = true
			
			let originalCellProvider = item.cellProvider
			item.cellProvider = { container, tableView, indexPath, rowInfo in
				let identifier = rowInfo.reuseIdentifier.stringValue
				
				var lookup = rowInfo.tableStorage.staticCellStorage ?? [:]
				if let cell = lookup[identifier] {
					return cell
				}
				
				let cell = originalCellProvider(container, tableView, indexPath, rowInfo)
				lookup[identifier] = cell
				rowInfo.storage.staticCellStorage = lookup
				return cell
			}
		}
	}
}

extension TableBuilderStore.Keys {
	fileprivate var staticCellStorage: Key<[String: UITableViewCell]> { "_staticCellStorageAlternative" }
}
