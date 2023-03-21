//
//  TableBuilderStorage.swift
//  Demo
//
//  Created by Andreas Verhoeven on 21/03/2023.
//

import UIKit

enum TableBuilderStaticStorage {
	fileprivate static var activeBuilders = [Any]()
	fileprivate static var activeRowInfos = [Any]()
	fileprivate static var activeSectionInfos = [Any]()
	fileprivate static var activeIndexPaths = [IndexPath]()
}


extension TableBuilderStaticStorage {
	@discardableResult static internal func with<T, ContainerType: AnyObject>(builder: TableBuilder<ContainerType>, callback: () -> T) -> T {
		activeBuilders.append(builder)
		defer { activeBuilders.removeLast() }
		return callback()
	}
	
	@discardableResult static internal func with<T, ContainerType: AnyObject>(rowInfo: RowInfo<ContainerType>, callback: () -> T) -> T {
		activeRowInfos.append(rowInfo)
		defer { activeRowInfos.removeLast() }
		return callback()
	}
	
	@discardableResult static internal func with<T, ContainerType: AnyObject>(sectionInfo: SectionInfo<ContainerType>, callback: () -> T) -> T {
		activeSectionInfos.append(sectionInfo)
		defer { activeSectionInfos.removeLast() }
		return callback()
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

fileprivate protocol TableBuilderTableViewHaveble {
	var tableView: UITableView { get }
}

extension TableBuilder: TableBuilderTableViewHaveble {
	fileprivate var tableView: UITableView { dataSource.tableView }
}

extension TableBuilderContent {
	public static var currentTableView: UITableView? {
		(TableBuilderStaticStorage.activeBuilders.last as? TableBuilderTableViewHaveble)?.tableView
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

extension UIResponder {
	fileprivate var closestViewController: UIViewController? {
		var responder: UIResponder? = self
		while responder != nil && (responder is UIViewController) == false {
			responder = responder?.next
		}
		return responder as? UIViewController
	}
}