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
	
	public func scrollTo(_ position: UITableView.ScrollPosition = .none, animated: Bool = true) {
		guard let indexPath, let tableView = resolver?.tableView else { return }
		tableView.scrollToRow(at: indexPath, at: position, animated: animated)
	}
}

internal protocol TableItemReferenceResolver: AnyObject {
	var tableView: UITableView { get }
	
	func indexPath(for reference: TableItemIdentifier?) -> IndexPath?
	func cell(for reference: TableItemIdentifier?) -> UITableViewCell?
}
