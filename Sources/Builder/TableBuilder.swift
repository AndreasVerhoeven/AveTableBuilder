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
public final class TableBuilder<ContainerType: AnyObject>: NSObject, TableUpdatable, UITableViewDelegate {
	
	/// our container, weakly retained. Passed to all escaping closures
	private(set) weak var container: ContainerType?

	/// our builder closure. Gets passed the container, if it is still alive.
	public let updater: (ContainerType) -> TableContentBuilder<ContainerType>.Collection
	
	/// We use a TableViewDataSource to do diffing for us and update the table view.
	public typealias DataSourceType = TableViewDataSource<SectionInfo<ContainerType>, RowInfo<ContainerType>>
	public let dataSource: DataSourceType
	
	public typealias StateChangesCallback = () -> Void
	private(set) var stateChangeCallbacks = [StateChangesCallback]()
	
	private var seenSections = Set<TableItemIdentifier>()
	
	private var activeIndexPaths = [IndexPath]()
	private var activeRowInfos = [RowInfo<ContainerType>]()
	private var activeSectionInfos = [SectionInfo<ContainerType>]()
	
	internal var rowInfoStorage = [RowInfo<ContainerType>.StorageKey: Any]()
	internal var sectionInfoStorage = [SectionInfo<ContainerType>.StorageKey: Any]()
	
	/// Creates a TableBuilder:
	///
	/// Parameters:
	///	- tableView: the table view to show contents in. its datasource and delegate will be replaced.
	///	- container: the container we are in. This will be retained weakly and will be passed to every escaping closure. We will also scan for `@TableState`s in the container.
	///	- updater: the @resultsBuilder that creates sections.
	public init(
		tableView: UITableView,
		container: ContainerType,
		@TableContentBuilder<ContainerType> updater: @escaping (ContainerType) -> TableContentBuilder<ContainerType>.Collection
	) {
		self.container = container
		self.updater = updater
		self.dataSource = DataSourceType(tableView: tableView, cellProvider: {  tableView, item, indexPath in
			return UITableViewCell()
		})
		
		super.init()
		
		dataSource.cellProvider = { [weak container, weak self] tableView, item, indexPath in
			guard let self, let container else { return UITableViewCell(style: .default, reuseIdentifier: nil) }
			return self.perform(with: item) {
				return item.cellProvider(container, tableView, indexPath, item)
			}
		}
		
		self.dataSource.cellUpdater = { [weak container, weak self] tableView, cell, item, indexPath, animated in
			guard let self, let container else { return }
			cell.selectionStyle = item.selectionHandlers.isEmpty ? .none : .default
			self.perform(with: item) {
				item.configurationHandlers.forEach { $0(container, cell, animated && item.animatedContentUpdates) }
			}
		}
		
		self.dataSource.headerTitleProvider = { tableView, section, index in
			return section.headerViewProvider == nil ? section.header : nil
		}
		self.dataSource.footerTitleProvider = { tableView, section, index in
			return section.footerViewProvider == nil ? section.footer : nil
		}
		
		self.dataSource.headerViewUpdater = { [weak container, weak self] tableView, view, section, index, animated in
			guard let self, let container else { return }
			if section.headerViewProvider == nil {
				let text = tableView.style != .plain ? section.header?.uppercased() : section.header
				(view as? UITableViewHeaderFooterView)?.textLabel?.setText(text, animated: animated)
				view.setNeedsLayout()
				view.invalidateIntrinsicContentSize()
			} else if let view = view as? UITableViewHeaderFooterView {
				self.perform(with: section) {
					section.headerUpdaters.forEach { $0(container, view, section.header, animated) }
				}
			}
		}
		
		self.dataSource.footerViewUpdater = { [weak container, weak self] tableView, view, section, index, animated in
			guard let self, let container else { return }
			if section.footerViewProvider == nil {
				(view as? UITableViewHeaderFooterView)?.textLabel?.setText(section.footer, animated: animated)
				view.setNeedsLayout()
				view.invalidateIntrinsicContentSize()
			} else if let view = view as? UITableViewHeaderFooterView {
				self.perform(with: section) {
					section.footerUpdaters.forEach { $0(container, view, section.footer, animated) }
				}
			}
		}
		
		self.dataSource.commitEditingStyle = { [weak container, weak self] tableView, item, indexPath, style in
			guard let container, let self else { return }
			switch style {
				case .none:
					break
					
				case .insert:
					return self.perform(indexPath: indexPath, with: item) {
						item.onCommitInsertHandlers.forEach { $0(container) }
					}
					
				case .delete:
					return self.perform(indexPath: indexPath, with: item) {
						item.onCommitDeleteHandlers.forEach { $0(container) }
					}
					
				@unknown default:
					break
			}
		}
		
		tableView.delegate = self
		self.registerUpdaters(in: container)
		update(animated: false)
	}
	
	/// Creates a TableBuilder from a UITableViewController, the controller being the container also.
	public convenience init(
		controller: ContainerType,
		@TableContentBuilder<ContainerType> updater: @escaping (ContainerType) -> TableContentBuilder<ContainerType>.Collection
	) where ContainerType: UITableViewController {
		self.init(tableView: controller.tableView, container: controller, updater: updater)
	}
	
	/// Triggers an update of the table view
	public func update(animated: Bool) {
		guard let container else { return }
		
		let reallyAnimated = (animated && dataSource.tableView.window != nil)
		
		var snapshot = DataSourceType.SnapshotType()
		for item in updater(container).items {
			item.rowInfos.forEach { row in
				row.reference.forEach { $0.wrappedValue = row.id }
			}
			
			if seenSections.contains(item.sectionInfo.id) == false {
				seenSections.insert(item.sectionInfo.id)
				item.sectionInfo.firstAddedCallbacks.forEach { $0(container, dataSource.tableView) }
			}
			
			snapshot.addItems(item.rowInfos, for: item.sectionInfo)
		}
		
		dataSource.apply(snapshot, animated: reallyAnimated)
		
		if reallyAnimated == true {
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
		item.onChange { [weak self] in
			self?.stateChangeCallbacks.forEach { $0() }
			self?.update(animated: true)
		}
	}
	
	/// Scans an object for `TableState` and makes sure that when those states
	/// change, the tableview is updated.
	public func registerUpdaters<T: AnyObject>(in container: T) {
		for child in Mirror(reflecting: container).children {
			if let item = child.value as? TableUpdateNotifyable {
				registerUpdater(item)
			}
		}
	}
	
	/// Callback will be called when any of the registered `TableState`s variables changes.
	public func onStateChange(_ callback: @escaping StateChangesCallback) {
		stateChangeCallbacks.append(callback)
	}
	
	// MARK: - UITableViewDelegate
	public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard let container else { return nil }
		guard let item = dataSource.currentSnapshot.sectionOrNil(at: section) else { return nil }
		return self.perform(with: item) {
			guard let view = item.headerViewProvider?(container, tableView, section) else { return nil }
			dataSource.headerViewUpdater?(tableView, view, item, section, false)
			return view
		}
	}
	
	public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		guard let container else { return nil }
		guard let item = dataSource.currentSnapshot.sectionOrNil(at: section) else { return nil }
		return self.perform(with: item) {
			guard let view = item.footerViewProvider?(container, tableView, section) else { return nil }
			dataSource.footerViewUpdater?(tableView, view, item, section, false)
			return view
		}
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		guard let container else { return }
		guard let item = dataSource.item(at: indexPath) else { return }
		return perform(indexPath: indexPath, with: item) {
			item.selectionHandlers.forEach { $0(container) }
		}
	}
	
	public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard let container else { return nil }
		guard let item = dataSource.item(at: indexPath) else { return nil }
		return perform(indexPath: indexPath, with: item) {
			return item.leadingSwipeActionsProvider?(container)
		}
	}
	
	public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard let container else { return nil }
		guard let item = dataSource.item(at: indexPath) else { return nil }
		return perform(indexPath: indexPath, with: item) {
			return item.trailingSwipeActionsProvider?(container)
		}
	}
	
	public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let container else { return nil }
		guard let item = dataSource.item(at: indexPath) else { return nil }
		return perform(indexPath: indexPath, with: item) {
			item.contextMenuProvider?(container, point, tableView.cellForRow(at: indexPath))
		}
	}
	
	public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		guard let item = dataSource.item(at: indexPath) else { return .none }
		return item.editingStyle ?? .none
	}
	
	public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		guard let item = dataSource.item(at: indexPath) else { return true }
		return item.shouldIndentWhileEditing ?? true
	}
	
	public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		guard let item = dataSource.item(at: indexPath) else { return true }
		if tableView.isEditing == true {
			return item.allowsHighlightingDuringEditing ?? false
		} else {
			return item.allowsHighlighting ?? true
		}
	}
}


fileprivate enum TableBuilderStaticStorage {
	static var activeBuilders = [Any]()
}

extension TableBuilder {
	public static var currentBuilder: TableBuilder<ContainerType>? {
		TableBuilderStaticStorage.activeBuilders.last as? TableBuilder<ContainerType>
	}
	
	fileprivate static var currentIndexPath: IndexPath? {
		return Self.currentBuilder?.activeIndexPaths.last
	}
	
	fileprivate static var currentRowInfo: RowInfo<ContainerType>? {
		return Self.currentBuilder?.activeRowInfos.last
	}
	
	fileprivate static var currentSectionInfo: SectionInfo<ContainerType>? {
		return Self.currentBuilder?.activeSectionInfos.last
	}
	
	private func perform<T>(callback: () -> T) -> T {
		TableBuilderStaticStorage.activeBuilders.append(self)
		let result = callback()
		TableBuilderStaticStorage.activeBuilders.removeLast()
		return result
	}
	
	private func perform<T>(with item: RowInfo<ContainerType>, callback: () -> T) -> T {
		activeRowInfos.append(item)
		let result = callback()
		activeRowInfos.removeLast()
		return result
	}
	
	private func perform<T>(indexPath: IndexPath? = nil, with item: SectionInfo<ContainerType>, callback: () -> T) -> T {
		TableBuilderStaticStorage.activeBuilders.append(self)
		let result = callback()
		TableBuilderStaticStorage.activeBuilders.removeLast()
		return result
	}
	
	private func perform<T>(indexPath: IndexPath? = nil, with item: RowInfo<ContainerType>, callback: () -> T) -> T {
		if let indexPath {
			activeIndexPaths.append(indexPath)
		}
		activeRowInfos.append(item)
		let result = perform(with: item, callback: callback)
		activeRowInfos.removeLast()
		if indexPath != nil {
			activeIndexPaths.removeLast()
		}
		return result
	}
}

extension TableContent {
	public static var currentSectionInfo: SectionInfo<ContainerType>? {
		TableBuilder<ContainerType>.currentSectionInfo
	}
}

extension RowInfo {
	public static var currentRowInfo: RowInfo<ContainerType>? {
		TableBuilder<ContainerType>.currentRowInfo
	}
}

extension SectionContent {
	public static var currentRowInfo: RowInfo<ContainerType>? {
		TableBuilder<ContainerType>.currentRowInfo
	}
	
	public static var currentTableView: UITableView? {
		TableBuilder<ContainerType>.currentBuilder?.dataSource.tableView
	}
	
	public static var currentIndexPath: IndexPath? {
		TableBuilder<ContainerType>.currentIndexPath
	}
	
	public static var currentCell: UITableViewCell? {
		guard let currentTableView, let currentIndexPath else { return nil }
		return currentTableView.cellForRow(at: currentIndexPath)
	}
	
	public static var closestViewController: UIViewController? {
		return currentTableView?.closestViewController
	}
}

extension UIResponder {
	fileprivate var closestViewController: UIViewController? {
		var responder: UIResponder? = self
		while responder != nil && (responder is UIViewController) == false {
			responder = responder?.next
		}
		return responder as? UIViewController
	}
}
