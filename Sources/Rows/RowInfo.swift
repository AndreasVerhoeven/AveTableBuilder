//
//  RowInfo.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit

/// This holds all information to create, configure and interact with a row.
/// It's a generic so that we can pass a typed ContainerType to each callback, so that
/// users of this class don't create retain cycles.
public class RowInfo<ContainerType: AnyObject>: IdentifiableTableItem {
	public var id: TableItemIdentifier = .empty
	
	/// provides a cell for this row. Convenience provider for external cells.
	public typealias CellProviderHandler = (_ `self`: ContainerType, _ tableView: UITableView, _ indexPath: IndexPath, _ rowInfo: RowInfo<ContainerType> ) -> UITableViewCell
	public var cellProvider: CellProviderHandler
	
	public func provideCell(container: ContainerType, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
		return cellProvider(container, tableView, indexPath, self)
	}
	
	public var cellClass: UITableViewCell.Type
	public var cellStyle: UITableViewCell.CellStyle
	
	/// a list of modifications we know are done. Used to build a unique reuseIdentifier. See `ReuseIdentifier`
	public var knownModifications: RowConfiguration
	
	/// configuration handlers, called in-order
	public typealias SimpleConfigurationHandler = (_ `self`: ContainerType, _ cell: UITableViewCell, _ animated: Bool) -> Void
	public typealias ConfigurationHandler = (_ `self`: ContainerType, _ cell: UITableViewCell, _ animated: Bool, _ rowInfo: RowInfo<ContainerType>) -> Void
	public var configurationHandlers = [ConfigurationHandler]()
	
	public func runModificationHandlers(container: ContainerType, cell: UITableViewCell, animated: Bool) {
		for (_, value) in modificationHandlers {
			if case let .handler(handler, _) = value {
				handler(container, cell, animated, self)
			}
		}
	}
	
	public func onConfigure(container: ContainerType, cell: UITableViewCell, animated: Bool) {
		runModificationHandlers(container: container, cell: cell, animated: animated)
		configurationHandlers.forEach { $0(container, cell, animated, self) }
	}
	
	/// selection handlers, called in-order
	public typealias SelectionHandler = (_ `self`: ContainerType, _ tableView: UITableView, _ indexPath: IndexPath, _ rowInfo: RowInfo<ContainerType>) -> Void
	public var selectionHandlers = [SelectionHandler]()
	
	public func onSelect(container: ContainerType, tableView: UITableView, indexPath: IndexPath) {
		selectionHandlers.forEach { $0(container, tableView, indexPath, self) }
	}
	
	/// swipe actions
	public typealias SimpleSwipeActionsProvider = ( _ `self`: ContainerType) -> UISwipeActionsConfiguration?
	public typealias SwipeActionsProvider = ( _ `self`: ContainerType, _ tableView: UITableView, _ indexPath: IndexPath, _ rowInfo: RowInfo<ContainerType>) -> UISwipeActionsConfiguration?
	public var leadingSwipeActionsProvider: SwipeActionsProvider?
	public var trailingSwipeActionsProvider: SwipeActionsProvider?
	
	public func leadingSwipActions(container: ContainerType, tableView: UITableView, indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return leadingSwipeActionsProvider?(container, tableView, indexPath, self)
	}
	
	public func trailingSwipeActions(container: ContainerType, tableView: UITableView, indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return trailingSwipeActionsProvider?(container, tableView, indexPath, self)
	}
	
	/// context menu
	public typealias SimpleContextMenuProvider = ( _ `self`: ContainerType, _ point: CGPoint, _ cell: UITableViewCell?) -> UIContextMenuConfiguration?
	public typealias ContextMenuProvider = ( _ `self`: ContainerType, _ point: CGPoint, _ cell: UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ row: RowInfo<ContainerType>) -> UIContextMenuConfiguration?
	public var contextMenuProvider: ContextMenuProvider?
	
	public func contextMenu(container: ContainerType, point: CGPoint, cell: UITableViewCell?, tableView: UITableView, indexPath: IndexPath) -> UIContextMenuConfiguration? {
		return contextMenuProvider?(container, point, cell, tableView, indexPath, self)
	}
	
	/// the editing style
	public var editingStyle: UITableViewCell.EditingStyle?
	public var shouldIndentWhileEditing: Bool?
	
	public typealias OnCommitEditingCallback = ( _ `self`: ContainerType, _ tableView: UITableView, _ indexPath: IndexPath, _ rowInfo: RowInfo<ContainerType>) -> Void
	public typealias SimpleOnCommitEditingCallback = ( _ `self`: ContainerType) -> Void
	public var onCommitInsertHandlers = [OnCommitEditingCallback]()
	public var onCommitDeleteHandlers = [OnCommitEditingCallback]()
	
	public func onCommitInsert(container: ContainerType, tableView: UITableView, indexPath: IndexPath) {
		onCommitInsertHandlers.forEach { $0(container, tableView, indexPath, self) }
	}
	
	public func onCommitDelete(container: ContainerType, tableView: UITableView, indexPath: IndexPath) {
		onCommitDeleteHandlers.forEach { $0(container, tableView, indexPath, self) }
	}
	
	
	/// finalizing
	public typealias FinalizeRowCallback = ( _ `self`: ContainerType, _ tableView: UITableView, _ rowInfo: RowInfo<ContainerType>) -> Void
	public var finalizeRowCallbacks = [FinalizeRowCallback]()
	
	public func finalize(container: ContainerType, tableView: UITableView) {
		finalizeRowCallbacks.forEach { $0(container, tableView, self) }
	}
	
	/// highlighting
	public var allowsHighlighting: Bool?
	public var allowsHighlightingDuringEditing: Bool?
	
	public var defaultCellColor: UIColor?
	
	/// references to items
	public var references = [TableItemReference]()
	
	/// true if we want animated content updates
	public var animatedContentUpdates = true
	
	/// storage for info about rows
	public let storage = TableBuilderStore()
	
	internal var creators = [SectionContent<ContainerType>]()
	
	public enum ModificationHandler {
		case manual
		case handler(ConfigurationHandler, RowModificationHandlerMode = .regular)
		
		var canBeOverriden: Bool {
			switch self {
				case .manual: return false
				case .handler(_, let mode): return mode == .canBeOverriden
			}
		}
	}
	
	public var modificationHandlers = [RowConfiguration.Item: ModificationHandler]()
	
	@discardableResult func addModification(for item: RowConfiguration.Item,
											force: Bool = false,
											mode: RowModificationHandlerMode = .regular,
											handler: @escaping ConfigurationHandler) -> Self {
		knownModifications.items.insert(item)
		
		guard force == true || (modificationHandlers[item]?.canBeOverriden ?? true) else { return self }
		modificationHandlers[item] = .handler(handler, mode)
		return self
	}
	
	public init<Cell: UITableViewCell>(
		cellClass: Cell.Type = UITableViewCell.self,
		style: UITableViewCell.CellStyle = .default,
		modifying: RowConfiguration,
		configuration: ((_ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void)?
	) {
		self.knownModifications = modifying
		self.cellClass = cellClass
		self.cellStyle = style
		self.cellProvider = { container, tableView, indexPath, info in
			return Self.createOrDequeue(tableView: tableView, cellClass: info.cellClass, style: info.cellStyle, reuseIdentifier: info.reuseIdentifier, indexPath: indexPath)
		}
		if let configuration {
			self.configurationHandlers.append { container, cell, animated, row in
				guard let cell = cell as? Cell else { return }
				configuration(container, cell, animated)
			}
		}
	}
	
	internal var reuseIdentifierShouldIncludeId = false
	internal var hasExplicitIdForForEach = false
	
	internal var reuseIdentifier: ReuseIdentifier {
		var reuseIdentifier = ReuseIdentifier(cellClass: cellClass, cellStyle: cellStyle, modifications: knownModifications)
		if reuseIdentifierShouldIncludeId == true {
			reuseIdentifier.fixedId = id
		}
		return reuseIdentifier
	}
}

extension RowInfo {
	func adapt<OtherContainerType: AnyObject>(to type: OtherContainerType.Type, from originalContainer: ContainerType) -> RowInfo<OtherContainerType> {
		
		TableBuilderStaticStorage.registerUpdaters(in: originalContainer)
		
		let rowInfo = RowInfo<OtherContainerType>(modifying: [], configuration: nil)
		rowInfo.id = id
		rowInfo.cellClass = cellClass
		rowInfo.cellStyle = cellStyle
		rowInfo.hasExplicitIdForForEach = hasExplicitIdForForEach
		rowInfo.allowsHighlighting = allowsHighlighting
		rowInfo.allowsHighlightingDuringEditing = allowsHighlightingDuringEditing
		rowInfo.references = references
		rowInfo.animatedContentUpdates = animatedContentUpdates
		rowInfo.knownModifications = knownModifications
		self.storage.chain(to: rowInfo.storage)
		
		for (key, value) in modificationHandlers {
			if case let .handler(handler, mode) = value {
				rowInfo.modificationHandlers[key] = .handler({ [weak originalContainer] container, cell, animated, rowInfo in
					guard let originalContainer else { return }
					return TableBuilderStaticStorage.with(rowInfo: self, container:originalContainer) {
						handler(originalContainer, cell, animated, self)
					}
				}, mode)
			} else {
				rowInfo.modificationHandlers[key] = .manual
			}
		}
		modificationHandlers.removeAll()
		
		rowInfo.cellProvider = { [weak originalContainer] container, tableView, indexPath, rowInfo in
			guard let originalContainer else { return UITableViewCell(style: .default, reuseIdentifier: nil) }
			self.cellStyle = rowInfo.cellStyle
			self.cellClass = rowInfo.cellClass
			return TableBuilderStaticStorage.with(rowInfo: self, container:originalContainer) {
				return self.provideCell(container: originalContainer, tableView: tableView, indexPath: indexPath)
			}
		}
		rowInfo.configurationHandlers = [{ [weak originalContainer] container, cell, animated, rowInfo in
			guard let originalContainer else { return }
			return TableBuilderStaticStorage.with(rowInfo: self) {
				return self.onConfigure(container: originalContainer, cell: cell, animated: animated)
			}
		}]
		
		if selectionHandlers.isEmpty == false {
			rowInfo.selectionHandlers = [ {[weak originalContainer] container, tableView, indexPath, rowInfo in
				guard let originalContainer else { return }
				return TableBuilderStaticStorage.with(rowInfo: self, container:originalContainer) {
					self.onSelect(container: originalContainer, tableView: tableView, indexPath: indexPath)
				}
			}]
		}
		
		if self.leadingSwipeActionsProvider != nil {
			rowInfo.leadingSwipeActionsProvider = { [weak originalContainer] container, tableView, indexPath, row in
				guard let originalContainer else { return nil }
				return TableBuilderStaticStorage.with(rowInfo: self, container:originalContainer) {
					return self.leadingSwipActions(container: originalContainer, tableView: tableView, indexPath: indexPath)
				}
			}
		}
		
		if self.trailingSwipeActionsProvider != nil {
			rowInfo.trailingSwipeActionsProvider = { [weak originalContainer] container,tableView, indexPath, row in
				guard let originalContainer else { return nil }
				return TableBuilderStaticStorage.with(rowInfo: self, container:originalContainer) {
					return self.trailingSwipeActions(container: originalContainer, tableView: tableView, indexPath: indexPath)
				}
			}
		}
		
		if self.contextMenuProvider != nil {
			rowInfo.contextMenuProvider = { [weak originalContainer] container, point, cell, tableView, indexPath, row in
				guard let originalContainer else { return nil }
				return TableBuilderStaticStorage.with(rowInfo: self, container:originalContainer) {
					return self.contextMenu(container: originalContainer, point: point, cell: cell, tableView: tableView, indexPath: indexPath)
				}
			}
		}
		
		rowInfo.onCommitInsertHandlers = [{ [weak originalContainer] container, tableView, indexPath, row in
			guard let originalContainer else { return }
			return TableBuilderStaticStorage.with(rowInfo: self, container:originalContainer) {
				self.onCommitInsert(container: originalContainer, tableView: tableView, indexPath: indexPath)
			}
		}]
		
		rowInfo.onCommitDeleteHandlers = [{ [weak originalContainer] container, tableView, indexPath, row in
			guard let originalContainer else { return }
			return TableBuilderStaticStorage.with(rowInfo: self, container:originalContainer) {
				self.onCommitDelete(container: originalContainer, tableView: tableView, indexPath: indexPath)
			}
		}]
		
		rowInfo.finalizeRowCallbacks = [{ [weak originalContainer] container, tableView, row in
			guard let originalContainer else { return }
			return TableBuilderStaticStorage.with(rowInfo: self, container:originalContainer) {
				self.finalize(container: originalContainer, tableView: tableView)
			}
		}]
		
		return rowInfo
	}
}

extension RowInfo {
	/// helper function to create or dequeu a cell
	public static func createOrDequeue<Cell: UITableViewCell>(tableView: UITableView, cellClass: Cell.Type, style: UITableViewCell.CellStyle = .default, reuseIdentifier: ReuseIdentifier, indexPath: IndexPath) -> Cell {
		let identifier = reuseIdentifier.stringValue
		//print(identifier)
		return (tableView.dequeueReusableCell(withIdentifier: identifier) as? Cell) ?? cellClass.init(style: style, reuseIdentifier: identifier)
	}
}


extension RowInfo {
	@discardableResult public func addingConfigurationHandler(modifying: RowConfiguration, handler: @escaping ConfigurationHandler) -> Self {
		modifying.items.forEach { modificationHandlers[$0] = .manual }
		knownModifications.append(modifying)
		configurationHandlers.append(handler)
		return self
	}
	
	@discardableResult public func prependingConfigurationHandler(modifying: RowConfiguration, handler: @escaping ConfigurationHandler) -> Self {
		modifying.items.forEach { modificationHandlers[$0] = .manual }
		knownModifications.append(modifying)
		configurationHandlers.insert(handler, at: 0)
		return self
	}
	
	@discardableResult public func addingSelectionHandler(_ handler: @escaping (_ `self`: ContainerType) -> Void) -> Self {
		selectionHandlers.append({ container, tableView, indexPath, rowInfo in
			handler(container)
		})
		return self
	}
	
	@discardableResult public func addingSelectionHandler(_ handler: @escaping (_ `self`: ContainerType, _ indexPath: IndexPath) -> Void) -> Self {
		selectionHandlers.append({ container, tableView, indexPath, rowInfo in
			handler(container, indexPath)
		})
		return self
	}
}

public enum RowModificationHandlerMode {
	case regular
	case canBeOverriden
}
