//
//  TableBuilderStorage.swift
//  Demo
//
//  Created by Andreas Verhoeven on 21/03/2023.
//

import UIKit

/// This is static storage to keep track of what is the active builder, row info, section info and index path
enum TableBuilderStaticStorage {
	fileprivate static var activeBuilders = [Any]()
	fileprivate static var activeRowInfos = [Any]()
	fileprivate static var activeSectionInfos = [Any]()
	fileprivate static var activeIndexPaths = [IndexPath]()
	fileprivate static var activeContainers = [Any]()
	fileprivate static var activeTableItemIdentifiers = [TableItemIdentifier]()
	
	fileprivate static var animatedUpdatesSupressedCount = 0
}

extension TableBuilderStaticStorage {
	@discardableResult static internal func with<T, ContainerType: AnyObject>(builder: TableBuilder<ContainerType>, callback: () -> T) -> T {
		activeBuilders.append(builder)
		defer { activeBuilders.removeLast() }
		return with(container: builder.container, callback: callback)
	}
	
	@discardableResult static internal func with<T>(container: Any?, callback: () -> T) -> T {
		guard let container = container else { return callback() }
		activeContainers.append(container)
		defer { activeContainers.removeLast() }
		return callback()
	}
	
	@discardableResult static internal func with<T, ContainerType: AnyObject>(rowInfo: RowInfo<ContainerType>, container: ContainerType? = nil, callback: () -> T) -> T {
		activeRowInfos.append(rowInfo)
		activeTableItemIdentifiers.append(rowInfo.id)
		defer {
			activeRowInfos.removeLast()
			activeTableItemIdentifiers.removeLast()
		}
		return with(container: container, callback: callback)
	}
	
	@discardableResult static internal func with<T, ContainerType: AnyObject>(sectionInfo: SectionInfo<ContainerType>, container: ContainerType? = nil, callback: () -> T) -> T {
		activeSectionInfos.append(sectionInfo)
		defer { activeSectionInfos.removeLast() }
		return with(container: container, callback: callback)
	}
	
	@discardableResult static internal func with<T>(indexPath: IndexPath?, callback: () -> T) -> T {
		guard let indexPath = indexPath else { return callback() }
		activeIndexPaths.append(indexPath)
		defer { activeIndexPaths.removeLast() }
		return callback()
	}
}

extension TableBuilder {
	var current: TableBuilder<ContainerType>? {
		return TableBuilderStaticStorage.activeBuilders.last as? TableBuilder<ContainerType>
	}
}

extension SectionInfo {
	public static var current: SectionInfo<ContainerType>? {
		return TableBuilderStaticStorage.activeSectionInfos.last as? SectionInfo<ContainerType>
	}
}

extension RowInfo {
	public static var current: RowInfo<ContainerType>? {
		TableBuilderStaticStorage.activeRowInfos.last as? RowInfo<ContainerType>
	}
}

fileprivate protocol TableBuilderProtocol: AnyObject {
	var tableView: UITableView { get }
	var storage: TableBuilderStore { get }
	
	func  update(animated: Bool)
	func registerUpdaters<T: AnyObject>(in container: T)
	@discardableResult func withAnimatedUpdatesSupressed<T>(callback: () -> T) -> T
}

extension TableBuilderStaticStorage {
	internal static func registerUpdaters<T: AnyObject>(in container: T) {
		(TableBuilderStaticStorage.activeBuilders.last as? TableBuilderProtocol)?.registerUpdaters(in: container)
	}
	
	internal static var currentContainer: Any? {
		return activeContainers.last
	}
	
	struct Updater {
		fileprivate weak var builder: TableBuilderProtocol?
		func update(animated: Bool) {
			builder?.update(animated: animated)
		}
	}
	
	internal static var currentUpdater: Updater? {
		guard let builder = TableBuilderStaticStorage.activeBuilders.last as? TableBuilderProtocol else { return nil }
		return Updater(builder: builder)
	}
	
	@discardableResult internal static func withAnimatedUpdates<T>(suppressed: Bool, callback: () -> T) -> T {
		guard suppressed == true else { return callback() }
		return withAnimatedUpdatesSupressed(callback: callback)
	}
	
	@discardableResult internal static func withAnimatedUpdatesSupressed<T>(callback: () -> T) -> T {
		Self.animatedUpdatesSupressedCount += 1
		defer { Self.animatedUpdatesSupressedCount -= 1 }
		return callback()
	}
	
	internal static var shouldSupressAnimatedUpdates: Bool { animatedUpdatesSupressedCount > 0 }
}

extension TableBuilder: TableBuilderProtocol {}
protocol TableStorageProvider {}

extension TableStorageProvider {
	public var tableStorage: TableBuilderStore {
		Self.tableStorage
	}
	
	public static var tableStorage: TableBuilderStore {
		return (TableBuilderStaticStorage.activeBuilders.last as? TableBuilderProtocol)?.storage ?? .init()
	}
}

extension TableBuilderContent: TableStorageProvider {}
extension RowInfo: TableStorageProvider {}
extension SectionInfo: TableStorageProvider {}

extension TableBuilderContent {
	public static var currentTableView: UITableView? {
		(TableBuilderStaticStorage.activeBuilders.last as? TableBuilderProtocol)?.tableView
	}
	
	public static var currentIndexPath: IndexPath? {
		TableBuilderStaticStorage.activeIndexPaths.last
	}
	
	public static var currentCell: UITableViewCell? {
		guard let currentTableView, let currentIndexPath else { return nil }
		return currentTableView.cellForRow(at: currentIndexPath)
	}
	
	public static var closestViewController: UIViewController? {
		return currentTableView?.closestViewController
	}
}

extension TableItemReference {
	public static var current: TableItemReference? {
		guard let identifier = TableBuilderStaticStorage.activeTableItemIdentifiers.last else { return nil }
		let reference = TableItemReference(wrappedValue: identifier)
		reference.resolver = TableBuilderStaticStorage.activeBuilders.last as? TableItemReferenceResolver
		return reference
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
