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
	
	public typealias SimpleHeaderFooterProvider = (_ `self`: ContainerType, _ tableView: UITableView,  _ section: Int) -> UITableViewHeaderFooterView?
	public typealias SimpleHeaderFooterUpdater = ( _ `self`: ContainerType, _ view: UITableViewHeaderFooterView, _ text: String?, _ animated: Bool) -> Void
	public typealias SimpleInitializationCallbacks = ( _ `self`: ContainerType, _ tableView: UITableView) -> Void
	
	public typealias HeaderFooterProvider = (_ `self`: ContainerType, _ tableView: UITableView,  _ section: Int, _ info: SectionInfo<ContainerType>) -> UITableViewHeaderFooterView?
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
	
	// to store info in
	public let storage = TableBuilderStore()
	
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
	
	public init(header: String? = nil, footer: String? = nil) {
		self.header = header
		self.footer = footer
	}
}

extension SectionInfo {
	func adapt<OtherContainerType: AnyObject>(to type: OtherContainerType.Type, from originalContainer: ContainerType) -> SectionInfo<OtherContainerType> {
		let sectionInfo = SectionInfo<OtherContainerType>(header: self.header, footer: self.footer)
		self.storage.chain(to: sectionInfo.storage)
		
		if footerViewProvider != nil {
			sectionInfo.footerViewProvider = { [weak originalContainer]  container, tableView, section, info in
				guard let originalContainer else { return nil }
				return TableBuilderStaticStorage.with(sectionInfo: self) {
					self.header = self.header ?? info.header
					self.footer = self.footer ?? info.footer
					return self.provideFooterView(container: originalContainer, tableView: tableView, section: section)
				}
			}
		}
		
		if headerViewProvider != nil {
			sectionInfo.headerViewProvider = { [weak originalContainer]  container, tableView, section, info in
				guard let originalContainer else { return nil }
				return TableBuilderStaticStorage.with(sectionInfo: self) {
					self.header = self.header ?? info.header
					self.footer = self.footer ?? info.footer
					return self.provideHeaderView(container: originalContainer, tableView: tableView, section: section)
				}
			}
		}
		
		sectionInfo.headerUpdaters.append { [weak originalContainer] container, view, text, tableView, section, animated, info in
			guard let originalContainer else { return }
			TableBuilderStaticStorage.with(sectionInfo: self) {
				self.header = self.header ?? info.header
				self.footer = self.footer ?? info.footer
				self.updateHeaderView(container: originalContainer, view: view, tableView: tableView, section: section, animated: animated)
			}
		}
		
		sectionInfo.footerUpdaters.append { [weak originalContainer] container, view, text, tableView, section, animated, info in
			guard let originalContainer else { return }
			TableBuilderStaticStorage.with(sectionInfo: self) {
				self.header = self.header ?? info.header
				self.footer = self.footer ?? info.footer
				self.updateFooterView(container: originalContainer, view: view, tableView: tableView, section: section, animated: animated)
			}
		}
		
		sectionInfo.firstAddedCallbacks.append { [weak originalContainer] container, tableView, info in
			guard let originalContainer else { return }
			TableBuilderStaticStorage.with(sectionInfo: self) {
				self.header = self.header ?? info.header
				self.footer = self.footer ?? info.footer
				self.performInitializationCallback(container: originalContainer, tableView: tableView)
			}
		}
		
		return sectionInfo
	}
}
