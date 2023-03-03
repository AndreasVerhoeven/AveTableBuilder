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
public struct RowInfo<ContainerType>: IdentifiableTableItem {
	public var id: TableItemIdentifier = .empty
	
	/// provides a cell for this row
	public typealias CellProviderHandler = (_ `self`: ContainerType, _ tableView: UITableView, _ indexPath: IndexPath, _ reuseIdentifier: ReuseIdentifier ) -> UITableViewCell
	public var cellProvider: CellProviderHandler
	public var cellClass: UITableViewCell.Type
	public var cellStyle: UITableViewCell.CellStyle
	
	/// a list of modifications we know are done. Used to build a unique reuseIdentifier. See `ReuseIdentifier`
	public var knownModifications: RowConfiguration
	
	/// configuration handlers, called in-order
	public typealias ConfigurationHandler = (_ `self`: ContainerType, _ cell: UITableViewCell, _ animated: Bool) -> Void
	public var configurationHandlers = [ConfigurationHandler]()
	
	/// selection handlers, called in-order
	public typealias SelectionHandler = (_ `self`: ContainerType) -> Void
	public var selectionHandlers = [SelectionHandler]()
	
	/// swipe actions
	public typealias SwipeActionsProvider = ( _ `self`: ContainerType) -> UISwipeActionsConfiguration?
	public var leadingSwipeActionsProvider: SwipeActionsProvider?
	public var trailingSwipeActionsProvider: SwipeActionsProvider?
	
	/// context menu
	public typealias ContextMenuProvider = ( _ `self`: ContainerType, _ point: CGPoint, _ cell: UITableViewCell? ) -> UIContextMenuConfiguration?
	public var contextMenuProvider: ContextMenuProvider?
	
	/// references to items
	public var reference = [TableItemReference]()
	
	public init<Cell: UITableViewCell>(
		cellClass: Cell.Type = UITableViewCell.self,
		style: UITableViewCell.CellStyle = .default,
		modifying: RowConfiguration,
		configuration: @escaping (_ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void
	) {
		self.knownModifications = modifying
		self.cellClass = cellClass
		self.cellStyle = style
		self.cellProvider = { container, tableView, indexPath, reuseIdentifier in
			Self.createOrDequeue(tableView: tableView, cellClass: cellClass, style: style, reuseIdentifier: reuseIdentifier, indexPath: indexPath)
		}
		self.configurationHandlers.append { container, cell, animated in
			guard let cell = cell as? Cell else { return }
			configuration(container, cell, animated)
		}
	}
	
	internal var reuseIdentifierShouldIncludeId = false
	
	internal var reuseIdentifier: ReuseIdentifier {
		var reuseIdentifier = ReuseIdentifier(cellClass: cellClass, cellStyle: cellStyle, modifications: knownModifications)
		if reuseIdentifierShouldIncludeId == true {
			reuseIdentifier.fixedId = id
		}
		return reuseIdentifier
	}
}

extension RowInfo {
	/// helper function to create or dequeu a cell
	public static func createOrDequeue<Cell: UITableViewCell>(tableView: UITableView, cellClass: Cell.Type, style: UITableViewCell.CellStyle = .default, reuseIdentifier: ReuseIdentifier, indexPath: IndexPath) -> Cell {
		let identifier = reuseIdentifier.stringValue
		//print(identifier)
		return (tableView.dequeueReusableCell(withIdentifier: identifier) as? Cell) ?? Cell(style: style, reuseIdentifier: identifier)
	}
}


extension RowInfo {
	public func addingConfigurationHandler(modifying: RowConfiguration, handler: @escaping ConfigurationHandler) -> Self {
		var item = self
		item.knownModifications.append(modifying)
		item.configurationHandlers.append(handler)
		return item
	}
	
	public func prependingConfigurationHandler(modifying: RowConfiguration, handler: @escaping ConfigurationHandler) -> Self {
		var item = self
		item.knownModifications.append(modifying)
		item.configurationHandlers.insert(handler, at: 0)
		return item
	}
	
	public func addingSelectionHandler(_ handler: @escaping SelectionHandler) -> Self {
		var item = self
		item.selectionHandlers.append(handler)
		return item
	}
}
