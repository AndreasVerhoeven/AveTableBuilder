//
//  TableItemMultiReference.swift
//  Demo
//
//  Created by Andreas Verhoeven on 09/08/2023.
//

import UIKit

/// Reference to multiple table  item. Used to identify items.
/// Use it like this:
///  ```
///  @TableItemMultiReference var myRows
///  ...
///    Row.ForEach(["A", "B", "C"]) { item in
///         	Row(text: item)
///    }.reference(self.$myRows)
///  ...
///   let myRow = self.myRows.reference(for: "B")
///   myRow.scrollTo(animated: true)
///   myRow.becomeFirstResponderIfPossible()
/// ```
@propertyWrapper public class TableItemMultiReference {
	/// the value we wrap, which is always a TableItemIdentifier?
	public var wrappedValue = [TableItemIdentifier: TableItemReference]()
	
	/// creates a multi reference
	public init(wrappedValue: [TableItemIdentifier: TableItemReference] = [:]) {
		self.wrappedValue = wrappedValue
	}
	
	/// returns the wrapper, access it like `self.$myRowReference` to be able to call methods on this reference
	public var projectedValue: TableItemMultiReference { self }
	
	/// returns a specific reference by id. The id is always the last part of the identifier
	public func reference<T: Hashable>(for identifier: T) -> TableItemReference? {
		return wrappedValue[.custom(identifier)]
	}
}
