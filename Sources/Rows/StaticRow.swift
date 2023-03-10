//
//  StaticRow.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 02/03/2023.
//

import UIKit
import ObjectiveC.runtime

fileprivate enum StaticRowStorage {
	private static var associatedObjectPointer = 0
	
	private static func retrieve(in tableView: UITableView) -> [String: UITableViewCell] {
		(objc_getAssociatedObject(tableView, &Self.associatedObjectPointer) as? [String: UITableViewCell]) ?? [:]
	}
	
	fileprivate static func retrieve(_ key: String, in tableView: UITableView) -> UITableViewCell? {
		retrieve(in: tableView)[key]
	}
	
	fileprivate static func add(_ cell: UITableViewCell, forKey key: String, in tableView: UITableView) {
		var storage = retrieve(in: tableView)
		storage[key] = cell
		objc_setAssociatedObject(tableView, &Self.associatedObjectPointer, storage, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}
}

extension Row {
	open class Static: SectionContent<ContainerType> {
		
		/// Creates a static row that is always the same cell that is not reused.
		public init<Cell: UITableViewCell>(
			cellClass: Cell.Type = Cell.self,
			cellStyle: UITableViewCell.CellStyle = .default,
			initial: ((_ `self`: ContainerType, _ cell: Cell) -> Void)? = nil,
			updates: @escaping ( _ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void
		) {
			var item = RowInfo<ContainerType>(cellClass: cellClass, style: cellStyle, modifying: [], configuration: updates)
			item.reuseIdentifierShouldIncludeId = true
			item.cellProvider = { container, tableView, indexPath, rowInfo in
				let identifier = rowInfo.reuseIdentifier.stringValue
				if let cell = StaticRowStorage.retrieve(identifier, in: tableView) {
					return cell
				}
				
				let cell = Cell.init(style: cellStyle, reuseIdentifier: nil)
				StaticRowStorage.add(cell, forKey: identifier, in: tableView)
				initial?(container, cell)
				return cell
			}
			super.init(item: item)
		}
		
		/// Creates a static row that is always the same cell that is not reused using a creation block.
		public init<Cell: UITableViewCell>(
			create: @escaping (_ `self`: ContainerType) -> Cell,
			updates: @escaping ( _ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void
		) {
			var item = RowInfo<ContainerType>(cellClass: UITableViewCell.self, style: .default, modifying: [], configuration: { container, cell, animated in
				guard let cell = cell as? Cell else { return }
				updates(container, cell, animated)
			})
			item.reuseIdentifierShouldIncludeId = true
			item.cellProvider = { container, tableView, indexPath, rowInfo in
				let identifier = rowInfo.reuseIdentifier.stringValue
				if let cell = StaticRowStorage.retrieve(identifier, in: tableView) {
					return cell
				}
				
				let cell = create(container)
				StaticRowStorage.add(cell, forKey: identifier, in: tableView)
				return cell
			}
			super.init(item: item)
		}
		
		/// Creates a static row from a pre existing cell
		public init<Cell: UITableViewCell>(cell: Cell, updates: @escaping ( _ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void) {
			var item = RowInfo<ContainerType>(cellClass: UITableViewCell.self, style: .default, modifying: [], configuration: { container, cell, animated in
				guard let cell = cell as? Cell else { return }
				updates(container, cell, animated)
			})
			item.reuseIdentifierShouldIncludeId = true
			item.cellProvider = { container, tableView, indexPath, rowInfo in
				return cell
			}
			super.init(item: item)
		}
		
		/// Creates a static row from a pre existing cell
		public init<Cell: UITableViewCell>(cell: Cell) {
			var item = RowInfo<ContainerType>(cellClass: UITableViewCell.self, style: .default, modifying: [], configuration: { container, cell, animated in
				// does nothing
			})
			item.reuseIdentifierShouldIncludeId = true
			item.cellProvider = { container, tableView, indexPath, rowInfo in
				return cell
			}
			super.init(item: item)
		}
	}
}
