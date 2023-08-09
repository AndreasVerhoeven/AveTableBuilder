//
//  TableIdentifier.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

/// An identifier for `Table*` items. We build a trail of identifiers in our @resultBuilder implementations,
/// so we can statically identify rows and sections based on their position in code.
///
/// It kinda works like:
///  ```
///  	Row() // id = offset(0)
///  	if someValue {
///  		Row() // id = offset(1).eitherFirst.offset(0)
///  		Row() // id = offset(1).eitherFirst.offset(1)
///  	} else {
///  			Row() // id = offset(1).eitherSecond.offset(0)
///  	}
///  ```
///  In reality, the list of identifiers is reversed (so `offset(0).eitherFirst.offset(1)` for the second row).
public struct TableItemIdentifier: Hashable {
	/// kind of identifier pieces, mapping to the @resultBuilder methods
	public enum Kind: Hashable {
		case optional
		case eitherFirst
		case eitherSecond
		case limitedAvailability
		case offset(Int)
		case custom(AnyHashable)
		case section(TableItemIdentifier)
	}
	
	/// List of items in this identifier
	public var items = [Kind]()
	
	// MARK: Factories
	public static var empty = Self()
	
	public static func kind(_ kind: Kind) -> Self {
		Self(items: [kind])
	}
	
	public static func offset(_ offset: Int) -> Self {
		Self(items: [.offset(offset)])
	}
	
	public static func custom<T: Hashable>(_ hashable: T) -> Self {
		Self(items: [.custom(AnyHashable(hashable))])
	}
	
	// MARK: - Appending
	public func appending(_ other: Self) -> Self {
		Self(items: items + other.items)
	}
	
	public func appending(_ kind: Kind) -> Self {
		appending(.kind(kind))
	}
	
	public mutating func append(_ other: Self) {
		items += other.items
	}
	
	public mutating func append(_ kind: Kind)  {
		items.append(kind)
	}
	
	public var onlyLastPart: TableItemIdentifier {
		guard let last = items.last else { return TableItemIdentifier() }
		return TableItemIdentifier(items: [last])
	}
	
	public var isEmpty: Bool { items.isEmpty }
	
	internal var stringValue: String {
		items.map{ String(describing: $0) }.joined(separator: ".")
	}
}

extension TableItemIdentifier: CustomDebugStringConvertible {
	public var debugDescription: String {
		return stringValue
	}
}

/// Protocol for items being identifiable by a TableItemIdentifier
public protocol IdentifiableTableItem: Identifiable {
	var id: TableItemIdentifier { get set }
}

/// helper functions to mutate an id
extension IdentifiableTableItem {
	public mutating func append(id: TableItemIdentifier) {
		self.id.append(id)
	}
	
	public func appending(id: TableItemIdentifier) -> Self {
		var item = self
		item.id.append(id)
		return item
	}

}
