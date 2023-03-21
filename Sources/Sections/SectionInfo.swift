//
//  SectionInfo.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit

/// This is the final result of creating Sections in a TableBuilder: it identifies a unique section
/// and how to configure this section.
public class SectionInfo<ContainerType: AnyObject>: IdentifiableTableItem {
	/// id of the section we represent
	public var id: TableItemIdentifier = .empty
	
	/// optional header text
	public var header: String?
	
	// optional footer text
	public var footer: String?
	
	public typealias SimpleHeaderFooterProvider = (_ `self`: ContainerType, _ tableView: UITableView,  _ section: Int) -> UITableViewHeaderFooterView
	public typealias SimpleHeaderFooterUpdater = ( _ `self`: ContainerType, _ view: UITableViewHeaderFooterView, _ text: String?, _ animated: Bool) -> Void
	public typealias SimpleInitializationCallbacks = ( _ `self`: ContainerType, _ tableView: UITableView) -> Void
	
	public typealias HeaderFooterProvider = (_ `self`: ContainerType, _ tableView: UITableView,  _ section: Int, _ info: SectionInfo<ContainerType>) -> UITableViewHeaderFooterView
	public typealias HeaderFooterUpdater = ( _ `self`: ContainerType, _ view: UITableViewHeaderFooterView, _ text: String?, _ tableView: UITableView,  _ section: Int, _ animated: Bool, _ info: SectionInfo<ContainerType>) -> Void
	public typealias InitializationCallbacks = ( _ `self`: ContainerType, _ tableView: UITableView, _ info: SectionInfo<ContainerType>) -> Void
	
	/// optional callback that provides a header view for this section
	public var headerViewProvider: HeaderFooterProvider?
	
	/// optional callback that provides a footer view for this section
	public var footerViewProvider: HeaderFooterProvider?
	
	/// callbacks that update the header view for this section
	public var headerUpdaters = [HeaderFooterUpdater]()
	
	/// callbacks that update the footer view for this section
	public var footerUpdaters = [HeaderFooterUpdater]()
	
	/// callbacks that are invoked when the section is first added to the table view
	public var firstAddedCallbacks = [InitializationCallbacks]()
	
	internal var creators = [TableContent<ContainerType>]()
	
	public func provideHeaderView(container: ContainerType, tableView: UITableView, section: Int) -> UITableViewHeaderFooterView? {
		headerViewProvider?(container, tableView, section, self)
	}
	
	public func provideFooterView(container: ContainerType, tableView: UITableView, section: Int) -> UITableViewHeaderFooterView? {
		headerViewProvider?(container, tableView, section, self)
	}
	
	public func updateHeaderView(container: ContainerType, view: UITableViewHeaderFooterView, tableView: UITableView, section: Int, animated: Bool) {
		headerUpdaters.forEach { $0(container, view, header, tableView, section, animated, self) }
	}
	
	public func updateFooterView(container: ContainerType, view: UITableViewHeaderFooterView, tableView: UITableView, section: Int, animated: Bool) {
		headerUpdaters.forEach { $0(container, view, header, tableView, section, animated, self) }
	}
	
	public func performInitializationCallback(container: ContainerType, tableView: UITableView) {
		firstAddedCallbacks.forEach { $0(container, tableView, self) }
	}

	public var storage = TableBuilderStore()
	
	public init(header: String? = nil, footer: String? = nil) {
		self.header = header
		self.footer = footer
	}
}
