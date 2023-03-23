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
public final class TableBuilder<ContainerType: AnyObject>: NSObject, TableUpdatable, UITableViewDelegate, TableItemReferenceResolver {
	
	/// our container, weakly retained. Passed to all escaping closures
	private(set) weak var container: ContainerType?

	/// our builder closure. Gets passed the container, if it is still alive.
	public let updater: (ContainerType) -> TableContentBuilder<ContainerType>.Collection
	
	/// We use a TableViewDataSource to do diffing for us and update the table view.
	public typealias DataSourceType = TableViewDataSource<SectionInfo<ContainerType>, RowInfo<ContainerType>>
	public let dataSource: DataSourceType
	
	public typealias StateChangesCallback = () -> Void
	private(set) var stateChangeCallbacks = [StateChangesCallback]()
	
	public var coalesceUpdates = true
	public var hasPendingUpdate = false
	
	private var seenSections = Set<TableItemIdentifier>()
	private var runLoopObserver: CFRunLoopObserver?
	private var debugShouldPrintIdentifiersOnUpdate = false
	
	private var supressAnimatedUpdatesCount = 0
	
	internal let storage = TableBuilderStore()
	
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
				return item.provideCell(container: container, tableView: tableView, indexPath: indexPath)
			}
		}
		
		self.dataSource.cellUpdater = { [weak container, weak self] tableView, cell, item, indexPath, animated in
			guard let self, let container else { return }
			cell.selectionStyle = item.selectionHandlers.isEmpty ? .none : .default
			self.perform(with: item) {
				item.onConfigure(container: container, cell: cell, animated: animated && item.animatedContentUpdates)
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
					section.updateHeaderView(container: container, view: view, tableView: tableView, section: index, animated: animated)
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
					section.updateFooterView(container: container, view: view, tableView: tableView, section: index, animated: animated)
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
						item.onCommitInsert(container: container, tableView: tableView, indexPath: indexPath)
					}
					
				case .delete:
					return self.perform(indexPath: indexPath, with: item) {
						item.onCommitInsert(container: container, tableView: tableView, indexPath: indexPath)
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
	
	public convenience init(tableView: UITableView,
							container: ContainerType,
							@SectionContentBuilder<ContainerType> updater: @escaping (ContainerType) -> SectionContentBuilder<ContainerType>.Collection
	) {
		self.init(tableView: tableView, container: container) { container in
			Section {
				updater(container)
			}
		}
	}
	
	public convenience init(
		controller: ContainerType,
		@SectionContentBuilder<ContainerType> updater: @escaping (ContainerType) -> SectionContentBuilder<ContainerType>.Collection
	) where ContainerType: UITableViewController {
		self.init(controller: controller) { container in
			Section {
				updater(container)
			}
		}
	}
	
	/// Triggers an update of the table view
	public func update(animated: Bool) {
		guard let container else { return }
		
		hasPendingUpdate = false
		if let runLoopObserver {
			CFRunLoopRemoveObserver(CFRunLoopGetMain(), runLoopObserver, CFRunLoopMode.commonModes);
			self.runLoopObserver = nil
		}
		
		perform {
			let reallyAnimated = (animated && dataSource.tableView.window != nil)
			
			if debugShouldPrintIdentifiersOnUpdate {
				print("<<<Debug Update Start>>>\n")
			}
			
			var snapshot = DataSourceType.SnapshotType()
			for item in updater(container).items {
				item.rowInfos.forEach { row in
					for reference in row.references {
						reference.wrappedValue = row.id
						reference.resolver = self
					}
					row.creators.forEach { $0.items = [] }
				}
				
				if seenSections.contains(item.sectionInfo.id) == false {
					seenSections.insert(item.sectionInfo.id)
					self.perform(with: item.sectionInfo) {
						item.sectionInfo.performInitializationCallback(container: container, tableView: dataSource.tableView)
					}
				}
				
				item.sectionInfo.creators.forEach { $0.items = [] }
				snapshot.addItems(item.rowInfos, for: item.sectionInfo)
				
				if debugShouldPrintIdentifiersOnUpdate {
					print("Section:")
					print(" Id = \"\(item.sectionInfo.id.stringValue)\"")
					print(" Number of rows = \(item.rowInfos.count)")
					if item.rowInfos.isEmpty == false {
						print(" Rows: ")
						for row in item.rowInfos {
							print( " - id: \"\(row.id.stringValue)\"")
							print( "  + reuse: \"\(row.reuseIdentifier.stringValue)\" ")
						}
					}
					
					print("\n")
				}
			}
			
			if debugShouldPrintIdentifiersOnUpdate {
				print("<<<Debug Update End>>>\n")
			}
			
			dataSource.apply(snapshot, animated: reallyAnimated)
			
			if reallyAnimated == true {
				DispatchQueue.main.async { [weak self] in
					self?.dataSource.tableView.performBatchUpdates { }
				}
			}
		}
	}
	
	public var tableView: UITableView {
		dataSource.tableView
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
	public func registerUpdater<T: SimpleChangeObservable>(_ item: T) {
		item.register(object: self) { [weak self] in
			self?.stateChangeCallbacks.forEach { $0() }
			self?.setNeedsUpdate()
		}
	}
	
	/// Scans an object for `TableState` and makes sure that when those states
	/// change, the tableview is updated.
	public func registerUpdaters<T: AnyObject>(in container: T) {
		for child in Mirror(reflecting: container).children {
			if let item = child.value as? SimpleChangeObservable {
				registerUpdater(item)
			}
		}
	}
	
	/// Callback will be called when any of the registered `TableState`s variables changes.
	public func onStateChange(_ callback: @escaping StateChangesCallback) {
		stateChangeCallbacks.append(callback)
	}
	
	
	/// will immediately call update when something changes
	public func immediateUpdates() -> Self {
		coalesceUpdates = false
		return self
	}
	
	public func setNeedsUpdate() {
		if TableBuilderStaticStorage.shouldSupressAnimatedUpdates || supressAnimatedUpdatesCount > 0 {
			return update(animated: false)
		}
		
		guard coalesceUpdates == true else { return update(animated: true) }
		guard hasPendingUpdate == false else { return }
		hasPendingUpdate = true
		
		// add an observer to execute once at the end of the runloop
		runLoopObserver = CFRunLoopObserverCreateWithHandler(nil, CFRunLoopActivity.beforeWaiting.rawValue, false, 0) { [weak self] observer, activity in
			self?.runLoopObserver = nil
			self?.update(animated: true)
		}
		if let runLoopObserver {
			CFRunLoopAddObserver(CFRunLoopGetMain(), runLoopObserver, CFRunLoopMode.commonModes)
		}
	}
	
	@discardableResult public func debugPrintIdentifiersOnUpdate() -> Self {
		debugShouldPrintIdentifiersOnUpdate = true
		return self
	}
	
	@discardableResult public func withAnimatedUpdatesSupressed<T>(callback: () -> T) -> T {
		supressAnimatedUpdatesCount += 1
		defer { supressAnimatedUpdatesCount -= 1 }
		return callback()
	}
	
	// MARK: - UITableViewDelegate
	public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard let container else { return nil }
		guard let item = dataSource.currentSnapshot.sectionOrNil(at: section) else { return nil }
		return self.perform(with: item) {
			guard let view = item.provideHeaderView(container: container, tableView: tableView, section: section) else { return nil }
			dataSource.headerViewUpdater?(tableView, view, item, section, false)
			return view
		}
	}
	
	public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		guard let container else { return nil }
		guard let item = dataSource.currentSnapshot.sectionOrNil(at: section) else { return nil }
		return self.perform(with: item) {
			guard let view = item.provideFooterView(container: container, tableView: tableView, section: section) else { return nil }
			dataSource.footerViewUpdater?(tableView, view, item, section, false)
			return view
		}
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		guard let container else { return }
		guard let item = dataSource.item(at: indexPath) else { return }
		return perform(indexPath: indexPath, with: item) {
			return item.onSelect(container: container, tableView: tableView, indexPath: indexPath)
		}
	}
	
	public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard let container else { return nil }
		guard let item = dataSource.item(at: indexPath) else { return nil }
		return perform(indexPath: indexPath, with: item) {
			return item.leadingSwipActions(container: container, tableView: tableView, indexPath: indexPath)
		}
	}
	
	public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard let container else { return nil }
		guard let item = dataSource.item(at: indexPath) else { return nil }
		return perform(indexPath: indexPath, with: item) {
			return item.trailingSwipeActions(container: container, tableView: tableView, indexPath: indexPath)
		}
	}
	
	public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard let container else { return nil }
		guard let item = dataSource.item(at: indexPath) else { return nil }
		return perform(indexPath: indexPath, with: item) {
			return item.contextMenu(container: container, point: point, cell: tableView.cellForRow(at: indexPath), tableView: tableView, indexPath: indexPath)
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

extension TableBuilder {
	private func perform<T>(callback: () -> T) -> T {
		return TableBuilderStaticStorage.with(builder: self, callback: callback)
	}
	
	private func perform<T>(with item: RowInfo<ContainerType>, callback: () -> T) -> T {
		return TableBuilderStaticStorage.with(rowInfo: item) { self.perform(callback: callback) }
	}
	
	private func perform<T>(indexPath: IndexPath? = nil, with item: SectionInfo<ContainerType>, callback: () -> T) -> T {
		return TableBuilderStaticStorage.with(indexPath: indexPath) {
			return TableBuilderStaticStorage.with(sectionInfo: item) { self.perform(callback: callback) }
		}
	}
	
	private func perform<T>(indexPath: IndexPath? = nil, with item: RowInfo<ContainerType>, callback: () -> T) -> T {
		return TableBuilderStaticStorage.with(indexPath: indexPath) {
			return TableBuilderStaticStorage.with(rowInfo: item) { self.perform(callback: callback) }
		}
	}
}
