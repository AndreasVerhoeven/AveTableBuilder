//
//  Section.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit
import AveFontHelpers

/// This is the most straight-forward implementation of TableContent: it represents a single section
/// with rows
open class Section<ContainerType: AnyObject>: TableContent<ContainerType> {
	/// Creates a section with optional header, optional footer and rows (thru a @resultsBuilder).
	public init(
		_ header: String? = nil,
		footer: String? = nil,
		@SectionContentBuilder<ContainerType> contents: () -> SectionContentBuilder<ContainerType>.Collection
	) {
		let sectionInfo = SectionInfo<ContainerType>(header: header, footer: footer)
		let rowInfos = contents().items
		super.init(item: .init(sectionInfo: sectionInfo, rowInfos: rowInfos))
	}
}

extension TableContent {
	/// Assign a custom header class to all sections in this content that do not have a header class configured yes.
	public func header<HeaderClass: UITableViewHeaderFooterView>(
		_ headerClass: HeaderClass.Type,
		updater: @escaping (_ `self`: ContainerType, _ view: HeaderClass, _ text: String?, _ animated: Bool) -> Void
	) -> Self {
		items.forEach { item in
			item.sectionInfo.header(headerClass, updater: updater)
		}
		return self
	}
	
	/// Assign a custom footer class to all sections in this content that do not have a header class configured yes.
	public func footer<FooterClass: UITableViewHeaderFooterView>(
		_ footerClass: FooterClass.Type,
		updater: @escaping (_ `self`: ContainerType, _ view: FooterClass, _ text: String?, _ animated: Bool) -> Void
	) -> Self {
		items.forEach { item in
			item.sectionInfo.footer(footerClass, updater: updater)
		}
		return self
	}
}
