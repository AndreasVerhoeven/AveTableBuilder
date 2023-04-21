//
//  StaticRow.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 02/03/2023.
//

import UIKit

extension Row {
	open class Static: SectionContent<ContainerType> {
		
		/// Creates a static row that is always the same cell that is not reused.
		public init<Cell: UITableViewCell>(
			cellClass: Cell.Type = Cell.self,
			cellStyle: UITableViewCell.CellStyle = .default,
			initial: ((_ `self`: ContainerType, _ cell: Cell) -> Void)? = nil,
			updates: @escaping ( _ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void
		) {
			let item = RowInfo<ContainerType>(cellClass: cellClass, style: cellStyle, modifying: [], configuration: updates)
			super.init(item: item)
			makeStatic()
		}
		
		/// Creates a static row that is always the same cell that is not reused using a creation block.
		public init<Cell: UITableViewCell>(
			create: @escaping (_ `self`: ContainerType) -> Cell,
			updates: @escaping ( _ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void
		) {
			let item = RowInfo<ContainerType>(cellClass: UITableViewCell.self, style: .default, modifying: [], configuration: { container, cell, animated in
				guard let cell = cell as? Cell else { return }
				updates(container, cell, animated)
			})
			item.cellProvider =  { container, tableView, IndexPath, rowInfo in
				create(container)
			}
			super.init(item: item)
			makeStatic()
		}
		
		/// Creates a static row from a pre existing cell
		public init<Cell: UITableViewCell>(cell: Cell, updates: @escaping ( _ container: ContainerType, _ cell: Cell, _ animated: Bool) -> Void) {
			let item = RowInfo<ContainerType>(cellClass: UITableViewCell.self, style: .default, modifying: [], configuration: { container, cell, animated in
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
			let item = RowInfo<ContainerType>(cellClass: UITableViewCell.self, style: .default, modifying: [], configuration: { container, cell, animated in
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
