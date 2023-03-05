//
//  ActionRow.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit

extension Row {
	// A row that signifies an action
	open class Action: Row<ContainerType, Action.Cell> {
		public class Cell: UITableViewCell {
			
			public override func tintColorDidChange() {
				super.tintColorDidChange()
				textLabel?.textColor = tintColor
				textLabel?.textAlignment = .center
			}
			
			public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
				super.init(style: style, reuseIdentifier: reuseIdentifier)
				
				textLabel?.textColor = tintColor
				textLabel?.textAlignment = .center
			}
			
			@available(*, unavailable)
			public required init?(coder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
		}
		
		
		public init(text: String?, action: RowInfo<ContainerType>.SelectionHandler? = nil) {
			super.init(cellClass: Cell.self) { container, cell, animated in
				cell.textLabel?.setText(text, animated: animated)
			}
			if let action {
				onSelect(action)
			}
		}
	}
}
