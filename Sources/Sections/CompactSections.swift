//
//  CompactSections.swift
//  Demo
//
//  Created by Andreas Verhoeven on 28/01/2024.
//

import UIKit

extension Section {
	/// Makes the spacing between sections compact by forcing a specific spacing **if** the sections do not have existing headers and footers
	open class Compact: TableContent<ContainerType> {
		public init(spacing: CGFloat = 8, @TableContentBuilder<ContainerType> builder: () -> TableContentBuilder<ContainerType>.Collection) {
			super.init(items: builder().items)
			
			_ = compactSections(spacing: spacing)
		}
	}
}


extension TableContent {
	/// Makes the spacing between sections compact by forcing a specific spacing **if** the sections do not have existing headers and footers
	func compactSections(spacing: CGFloat = 8) -> Self {
		for item in items{
			
			if item !== items.first {
				if item.sectionInfo.headerViewProvider != nil {
					item.sectionInfo.headerUpdaters.append({ container, view, text, tableView, index, animated, info in
						guard let view = view as? StylishedCustomHeader else { return }
						view.fixedHeight = (text == nil || text?.isEmpty == true) ? spacing * 0.5 : nil
					})
					
				} else if item.sectionInfo.header == nil {
					item.sectionInfo.header(EmptyFooterHeaderView.self) { container, view, text, animated in
						view.fixedHeight = spacing * 0.5
					}
				}
			}
			
			if item !== items.last {
				if item.sectionInfo.footerViewProvider != nil {
					item.sectionInfo.footerUpdaters.append({ container, view, text, tableView, index, animated, info in
						guard let view = view as? StylishedCustomHeader else { return }
						view.fixedHeight = (text == nil || text?.isEmpty == true) ? spacing * 0.5 : nil
					})
					
				} else if item.sectionInfo.footer == nil {
					item.sectionInfo.footer(EmptyFooterHeaderView.self) { container, view, text, animated in
						view.fixedHeight = spacing * 0.5
					}
				}
			}
		}
		
		return self
	}
}
