//
//  TableItemReference.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 02/03/2023.
//

import UIKit

/// Reference to a table item. Used to identify items.
/// Use it like this:
///  ```
///  @TableItemReference var myRow
///  ...
///  Row(text: "Some Row").reference(self.$myRow)
///  ...
///   self.$myRow.scrollTo(animated: true)
///   self.$myRow.becomeFirstResponderIfPossible()
/// ```
@propertyWrapper public class TableItemReference {
	/// the value we wrap, which is always a TableItemIdentifier?
	public var wrappedValue: TableItemIdentifier?
	
	/// the object resolving our references, usually a TableBuilder.
	internal weak var resolver: TableItemReferenceResolver?
	
	/// creates a reference
	public init(wrappedValue: TableItemIdentifier? = nil) {
		self.wrappedValue = wrappedValue
	}
	
	/// returns the wrapper, access it like `self.$myRowReference` to be able to call methods on this reference
	public var projectedValue: TableItemReference { self }
	
	/// gets the index path associated with this reference, if available
	public var indexPath: IndexPath? { resolver?.indexPath(for: wrappedValue) }
	
	/// gets the cell associated with this reference, if available
	public var cell: UITableViewCell? { resolver?.cell(for: wrappedValue) }
	
	/// scrolls to the row associated with this reference, if available
	public func scrollTo(_ position: UITableView.ScrollPosition = .none, animated: Bool = true) {
		guard let indexPath, let tableView = resolver?.tableView else { return }
		tableView.scrollToRow(at: indexPath, at: position, animated: animated)
	}
	
	
	/// makes the row associated with this reference the first responder, if possible. (E.g. if it is a `Row.TextField` or `Row.TextView`)
	@discardableResult public func becomeFirstResponderIfPossible() -> Bool {
		(cell as? RowFirstResponderBecomeable)?.makeFirstResponder() ?? false
	}
	
	/// invokes the selection action associated with this reference, if possible.
	@discardableResult public func invoke() -> Bool {
		resolver?.invoke(for: wrappedValue) ?? false
	}
}

/// internal protocol to perform actions
internal protocol TableItemReferenceResolver: AnyObject {
	var tableView: UITableView { get }
	
	func indexPath(for reference: TableItemIdentifier?) -> IndexPath?
	func cell(for reference: TableItemIdentifier?) -> UITableViewCell?
	func invoke(for reference: TableItemIdentifier?) -> Bool
}
