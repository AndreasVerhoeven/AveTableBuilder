//
//  SectionInfo.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit

/// This is the final result of creating Sections in a TableBuilder: it identifies a unique section
/// and how to configure this section.
public struct SectionInfo<ContainerType>: IdentifiableTableItem {
	/// id of the section we represent
	public var id: TableItemIdentifier = .empty
	
	/// optional header text
	public var header: String?
	
	// optional footer text
	public var footer: String?
	
	public typealias HeaderFooterProvider = (_ `self`: ContainerType, _ tableView: UITableView,  _ section: Int) -> UITableViewHeaderFooterView
	public typealias HeaderFooterUpdater = ( _ `self`: ContainerType, _ view: UIView, _ text: String?, _ animated: Bool) -> Void
	
	/// optional callback that provides a header view for this section
	public var headerViewProvider: HeaderFooterProvider?
	
	/// optional callback that provides a footer view for this section
	public var footerViewProvider: HeaderFooterProvider?
	
	/// callbacks that update the header view for this section
	public var headerUpdaters = [HeaderFooterUpdater]()
	
	/// callbacks that update the footer view for this section
	public var footerUpdaters = [HeaderFooterUpdater]()
}
