//
//  TableItemReference.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 02/03/2023.
//

import Foundation

/// Reference to a table item. Used to identify items.
@propertyWrapper public class TableItemReference {
	public var wrappedValue: TableItemIdentifier?
	
	public init(wrappedValue: TableItemIdentifier?) {
		self.wrappedValue = wrappedValue
	}
	
	public var projectedValue: TableItemReference { self }
}
