//
//  TableBuilder.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit
import AveDataSource

/// This is our Builder that builds, manages and updates a table view with the `Section` and `Row` description we use in its
/// @resultsBuilder parameter.
///
/// This class works by using @resultsBuilder to make unique identifiers for each row and section based on the @resultsBuilder
/// transforms: a place in code uniquely identifies a Row (and Section). This allows us to automatically diff rows, without
/// needing extra boilerplate identifiers for it. Each time the data source is updated, we call the results builder: the result is turned
/// into a snapshot based on the unique identifiers we generated.
///
/// Note that the first parameter of the resultsBuilder is `self`: we do this to stop retain-cycles. When constructing a TableBuilder,
/// you give it a container: the container is then passed to every escaping closure, so that you don't create retain cycles.
///
/// Using `@TableState` and `@TableBinding`, we can automatically update variables and automatically trigger updates.
/// By default, TableBuilder will register each `@TableState` in its container to apply an update automatically. If you want
/// to register other `@TableStates`, call `registerUpdater(_:)` or `registerUpdaters(in:)`.
///
/// Example:
/// ```
/// 		@TableState var condition = true
/// 		TableBuilder(controller: self) { `self` in
/// 				Section("First Section") {
/// 					Row(text: "Item 1")
/// 					Row.Switch(text: "Condition", binding: self.$someCondition)
///
/// 					if self.someCondition {
/// 						Row(text: "ConditionIsTrue")
/// 					} else {
/// 						Row(text: "ConditionIsFalse")
/// 					}
/// 				}
/// 		}
/// ```
final class TableBuilder<ContainerType: AnyObject>: NSObject, TableUpdatable, UITableViewDelegate {
	
	/// our container, weakly retained. Passed to all escaping closures
	private(set) weak var container: ContainerType?

	/// our builder closure. Gets passed the container, if it is still alive.
	public let updater: (ContainerType) -> TableContentBuilder<ContainerType>.Collection
	
	/// We use a TableViewDataSource to do diffing for us and update the table view.
	typealias DataSourceType = TableViewDataSource<SectionInfo<ContainerType>, RowInfo<ContainerType>>
	let dataSource: DataSourceType
	
	/// Creates a TableBuilder:
	///
	/// Parameters:
	///	- tableView: the table view to show contents in. its datasource and delegate will be replaced.
	///	- container: the container we are in. This will be retained weakly and will be passed to every escaping closure. We will also scan for `@TableState`s in the container.
	///	- updater: the @resultsBuilder that creates sections.
	init(
		tableView: UITableView,
		container: ContainerType,
		@TableContentBuilder<ContainerType> updater: @escaping (ContainerType) -> TableContentBuilder<ContainerType>.Collection
	) {
		self.container = container
		self.updater = updater
		self.dataSource = DataSourceType(tableView: tableView, cellProvider: { [weak container] tableView, item, indexPath in
			guard let container else { return UITableViewCell(style: .default, reuseIdentifier: nil) }
			return item.cellProvider(container, tableView, indexPath, item.reuseIdentifier)
		})
		
		self.dataSource.cellUpdater = { [weak container] tableView, cell, item, indexPath, animated in
			guard let container else { return }
			cell.selectionStyle = item.selectionHandlers.isEmpty ? .none : .default
			item.configurationHandlers.forEach { $0(container, cell, animated) }
		}
		
		self.dataSource.headerTitleProvider = { tableView, section, index in
			return section.headerViewProvider == nil ? section.header : nil
		}
		self.dataSource.footerTitleProvider = { tableView, section, index in
			return section.footerViewProvider == nil ? section.footer : nil
		}
		
		self.dataSource.headerViewUpdater = { [weak container] tableView, view, section, index, animated in
			guard let container else { return }
			if section.headerViewProvider == nil {
				let text = tableView.style != .plain ? section.header?.uppercased() : section.header
				(view as? UITableViewHeaderFooterView)?.textLabel?.setText(text, animated: animated)
				view.setNeedsLayout()
				view.invalidateIntrinsicContentSize()
			} else {
				section.headerUpdaters.forEach { $0(container, view, section.header, animated) }
			}
		}
		
		self.dataSource.footerViewUpdater = { [weak container] tableView, view, section, index, animated in
			guard let container else { return }
			if section.footerViewProvider == nil {
				(view as? UITableViewHeaderFooterView)?.textLabel?.setText(section.footer, animated: animated)
				view.setNeedsLayout()
				view.invalidateIntrinsicContentSize()
			} else {
				section.footerUpdaters.forEach { $0(container, view, section.footer, animated) }
			}
		}
		
		super.init()
		tableView.delegate = self
		self.registerUpdaters(in: container)
		update(animated: false)
	}
	
	/// Creates a TableBuilder from a UITableViewController, the controller being the container also.
	convenience init(
		controller: ContainerType,
		@TableContentBuilder<ContainerType> updater: @escaping (ContainerType) -> TableContentBuilder<ContainerType>.Collection
	) where ContainerType: UITableViewController {
		self.init(tableView: controller.tableView, container: controller, updater: updater)
	}
	
	/// Triggers an update of the table view
	public func update(animated: Bool) {
		guard let container else { return }
		
		var snapshot = DataSourceType.SnapshotType()
		for item in updater(container).items {
			item.rowInfos.forEach { row in
				row.reference.forEach { $0.wrappedValue = row.id }
				//print(row.id)
			}
			snapshot.addItems(item.rowInfos, for: item.sectionInfo)
		}
		
		dataSource.apply(snapshot, animated: animated)
		
		if animated == true {
			DispatchQueue.main.async { [weak self] in
				self?.dataSource.tableView.performBatchUpdates { }
			}
		}
	}
	
	/// gets the IndexPath in the tableview for the given identifier
	public func indexPath(for identifier: TableItemIdentifier?) -> IndexPath? {
		guard let identifier else { return nil }
		return dataSource.currentSnapshot.firstIndexPath { $0.id == identifier }
	}
	
	/// gets the cell for the row with the given identifier
	public func cell(for identifier: TableItemIdentifier?) -> UITableViewCell? {
		guard let indexPath = indexPath(for: identifier) else { return nil }
		return dataSource.tableView.cellForRow(at: indexPath)
	}
	
	/// Registers an item that, when changed, should update the tableview
	public func registerUpdater<T: TableUpdateNotifyable>(_ item: T) {
		item.onChange { [weak self] in self?.update(animated: true) }
	}
	
	/// Scans an object for `TableState` and makes sure that when those states
	/// change, the tableview is updated.
	func registerUpdaters<T: AnyObject>(in container: T) {
		for child in Mirror(reflecting: container).children {
			if let item = child.value as? TableUpdateNotifyable {
				registerUpdater(item)
			}
		}
	}
	
	// MARK: - UITableViewDelegate
	public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard let container else { return nil }
		guard let item = dataSource.currentSnapshot.sectionOrNil(at: section) else { return nil }
		guard let view = item.headerViewProvider?(container, tableView, section) else { return nil }
		dataSource.headerViewUpdater?(tableView, view, item, section, false)
		return view
	}
	
	public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		guard let container else { return nil }
		guard let item = dataSource.currentSnapshot.sectionOrNil(at: section) else { return nil }
		guard let view = item.footerViewProvider?(container, tableView, section) else { return nil }
		dataSource.footerViewUpdater?(tableView, view, item, section, false)
		return view
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		guard let container else { return }
		guard let item = dataSource.item(at: indexPath) else { return }
		item.selectionHandlers.forEach { $0(container) }
	}
	
	public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard let container else { return nil }
		guard let item = dataSource.item(at: indexPath) else { return nil }
		return item.leadingSwipeActionsProvider?(container)
	}
	
	public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard let container else { return nil }
		guard let item = dataSource.item(at: indexPath) else { return nil }
		return item.trailingSwipeActionsProvider?(container)
	}
	
	public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let container else { return nil }
		guard let item = dataSource.item(at: indexPath) else { return nil }
		return item.contextMenuProvider?(container, point, tableView.cellForRow(at: indexPath))
	}
}