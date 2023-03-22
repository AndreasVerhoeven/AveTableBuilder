//
//  TableItemReference.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 02/03/2023.
//

import UIKit

/// Reference to a table item. Used to identify items.
@propertyWrapper public class TableItemReference {
	public var wrappedValue: TableItemIdentifier?
	internal weak var resolver: TableItemReferenceResolver?
	
	public init(wrappedValue: TableItemIdentifier? = nil) {
		self.wrappedValue = wrappedValue
	}
	
	public var projectedValue: TableItemReference { self }
	
	public var indexPath: IndexPath? { resolver?.indexPath(for: wrappedValue) }
	public var cell: UITableViewCell? { resolver?.cell(for: wrappedValue) }
}

internal protocol TableItemReferenceResolver: AnyObject {
	func indexPath(for reference: TableItemIdentifier?) -> IndexPath?
	func cell(for reference: TableItemIdentifier?) -> UITableViewCell?
}
