//
//  RowNone.swift
//  Demo
//
//  Created by Andreas Verhoeven on 07/06/2023.
//

import UIKit

extension Row {
	/// Use this if you need a statement  in `switch`es that require you to have a row,
	/// without __any__ content
	class None: Row<ContainerType, UITableViewCell> {
		init() {
			super.init()
			items.removeAll()
		}
	}
}
