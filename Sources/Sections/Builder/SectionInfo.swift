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
	
	internal var hasExplicitIdForForEach = false
	
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
		footerViewProvider?(container, tableView, section, self)
	}
	
	public func updateHeaderView(container: ContainerType, view: UITableViewHeaderFooterView, tableView: UITableView, section: Int, animated: Bool) {
		headerUpdaters.forEach { $0(container, view, header, tableView, section, animated, self) }
	}
	
	public func updateFooterView(container: ContainerType, view: UITableViewHeaderFooterView, tableView: UITableView, section: Int, animated: Bool) {
		footerUpdaters.forEach { $0(container, view, header, tableView, section, animated, self) }
	}
	
	public func performInitializationCallback(container: ContainerType, tableView: UITableView) {
		firstAddedCallbacks.forEach { $0(container, tableView, self) }
	}
	
	public init(header: String? = nil, footer: String? = nil) {
		self.header = header
		self.footer = footer
	}
	
	/// Assign a custom header class to this section in this content that do not have a header class configured yes.
	public func header<HeaderClass: UITableViewHeaderFooterView>(
		_ headerClass: HeaderClass.Type,
		updater: @escaping (_ `self`: ContainerType, _ view: HeaderClass, _ text: String?, _ animated: Bool) -> Void
	) {
		guard headerViewProvider == nil else { return }
		headerViewProvider = { container, tableView, section, info in
			let identifier = "Header.\(NSStringFromClass(headerClass))"
			return (tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as? HeaderClass) ?? HeaderClass.init(reuseIdentifier: identifier)
		}
		headerUpdaters.insert({ container, view, text, tableView, index, animated, info in
			guard let view = view as? HeaderClass else { return }
			updater(container, view, text, animated)
		}, at: 0)
	}
	
	/// Assign a custom footer class this section in this content that do not have a header class configured yes.
	public func footer<FooterClass: UITableViewHeaderFooterView>(
		_ footerClass: FooterClass.Type,
		updater: @escaping (_ `self`: ContainerType, _ view: FooterClass, _ text: String?, _ animated: Bool) -> Void
	) {
		guard footerViewProvider == nil else { return }
		footerViewProvider = { container, tableView, section, info in
			let identifier = "Footer.\(NSStringFromClass(footerClass))"
			return (tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as? FooterClass) ?? FooterClass.init(reuseIdentifier: identifier)
		}
		footerUpdaters.append({ container, view, text, tableView, index, animated, info in
			guard let view = view as? FooterClass else { return }
			updater(container, view, text, animated)
		})
	}
}

extension SectionInfo {
	func adapt<OtherContainerType: AnyObject>(to type: OtherContainerType.Type, from originalContainer: ContainerType) -> SectionInfo<OtherContainerType> {
		let sectionInfo = SectionInfo<OtherContainerType>(header: self.header, footer: self.footer)
		sectionInfo.id = id
		sectionInfo.hasExplicitIdForForEach = hasExplicitIdForForEach
		self.storage.chain(to: sectionInfo.storage)
		
		if footerViewProvider != nil {
			sectionInfo.footerViewProvider = { [weak originalContainer]  container, tableView, section, info in
				guard let originalContainer else { return nil }
				return TableBuilderStaticStorage.with(sectionInfo: self) {
					self.header = self.header ?? info.header
					self.footer = self.footer ?? info.footer
					return TableBuilderStaticStorage.with(container: originalContainer) {
						return self.provideFooterView(container: originalContainer, tableView: tableView, section: section)
					}
				}
			}
		}
		
		if headerViewProvider != nil {
			sectionInfo.headerViewProvider = { [weak originalContainer]  container, tableView, section, info in
				guard let originalContainer else { return nil }
				return TableBuilderStaticStorage.with(sectionInfo: self) {
					self.header = self.header ?? info.header
					self.footer = self.footer ?? info.footer
					return TableBuilderStaticStorage.with(sectionInfo: self, container: originalContainer) {
						return self.provideHeaderView(container: originalContainer, tableView: tableView, section: section)
					}
				}
			}
		}
		
		sectionInfo.headerUpdaters.append { [weak originalContainer] container, view, text, tableView, section, animated, info in
			guard let originalContainer else { return }
			TableBuilderStaticStorage.with(sectionInfo: self) {
				self.header = self.header ?? info.header
				self.footer = self.footer ?? info.footer
				return TableBuilderStaticStorage.with(sectionInfo: self, container: originalContainer) {
					self.updateHeaderView(container: originalContainer, view: view, tableView: tableView, section: section, animated: animated)
				}
			}
		}
		
		sectionInfo.footerUpdaters.append { [weak originalContainer] container, view, text, tableView, section, animated, info in
			guard let originalContainer else { return }
			TableBuilderStaticStorage.with(sectionInfo: self) {
				self.header = self.header ?? info.header
				self.footer = self.footer ?? info.footer
				return TableBuilderStaticStorage.with(sectionInfo: self, container: originalContainer) {
					self.updateFooterView(container: originalContainer, view: view, tableView: tableView, section: section, animated: animated)
				}
			}
		}
		
		sectionInfo.firstAddedCallbacks.append { [weak originalContainer] container, tableView, info in
			guard let originalContainer else { return }
			TableBuilderStaticStorage.with(sectionInfo: self) {
				self.header = self.header ?? info.header
				self.footer = self.footer ?? info.footer
				return TableBuilderStaticStorage.with(sectionInfo: self, container: originalContainer) {
					self.performInitializationCallback(container: originalContainer, tableView: tableView)
				}
			}
		}
		
		return sectionInfo
	}
}
