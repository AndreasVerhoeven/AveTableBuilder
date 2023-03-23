//
//  StylishedRow.swift
//  Demo
//
//  Created by Andreas Verhoeven on 23/03/2023.
//

import UIKit

extension Row {
	open class Stylished: SectionContent<ContainerType> {
		public init(@SectionContentBuilder<ContainerType> builder: () -> SectionContentBuilder<ContainerType>.Collection) {
			Self.currentTableView?.backgroundColor = .systemBackground
			let section = Row.Group(builder: builder).stylished()
			super.init(items: section.items)
		}
	}
}

extension SectionContent {
	public func stylished() -> Self {
		backgroundColor(.secondarySystemBackground)
		_ = modifyRows { $0.defaultCellColor = $0.defaultCellColor ?? .secondarySystemBackground }
		return self
	}
}
