//
//  ConfigurationItem.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 02/03/2023.
//

import Foundation

/// This is a list of items that we know are modified in a row. see `ReuseIdentifier`.
public struct RowConfiguration {
	public struct Item: RawRepresentable, Hashable {
		public var rawValue: String
		
		public init(rawValue: String) {
			self.rawValue = rawValue
		}
		
		// cell config
		public static let backgroundColor = Self(rawValue: "_backgroundColor")
		public static let accessory = Self(rawValue: "_accessory")
		public static let accessoryView = Self(rawValue: "_accessoryView")
		
		// content
		public static let image = Self(rawValue: "_image")
		public static let text = Self(rawValue: "_text")
		public static let detailText = Self(rawValue: "_detailText")
		public static let accessoryText = Self(rawValue: "_accessoryText")
		
		// content configuration
		public static let textFont = Self(rawValue: "_textFont")
		public static let detailTextFont = Self(rawValue: "_detailTextFont")
		public static let accessoryTextFont = Self(rawValue: "_accessoryTextFont")
		
		public static let textColor = Self(rawValue: "_textColor")
		public static let detailTextColor = Self(rawValue: "_detailTextColor")
		public static let accessoryTextColor = Self(rawValue: "_accessoryTextColor")
		
		public static let textAlignment = Self(rawValue: "_textAlignment")
		public static let detailTextAlignment = Self(rawValue: "_detailTextAlignment")
		public static let accessoryTextAlignment = Self(rawValue: "_accessoryTextAlignment")
		
		public static let imageTintColor = Self(rawValue: "_imageTintColor")
		public static let numberOfLines = Self(rawValue: "_numberOfLines")
		
		// other
		public static let menu = Self(rawValue: "_menu")
		
		// indicates that this row is manually configured: it's up
		// to the programmer to make things consistent
		public static let manual = Self(rawValue: "_manual")
		
		// custom items for convenience
		public static let custom1 = Self(rawValue: "_custom1")
		public static let custom2 = Self(rawValue: "_custom2")
		public static let custom3 = Self(rawValue: "_custom3")
		public static let custom4 = Self(rawValue: "_custom4")
		public static let custom5 = Self(rawValue: "_custom5")
		
		public static func custom(_ name: String) -> Self {
			Self(rawValue: name)
		}
	}
	
	public var items = Set<Item>()
	
	public static let empty = Self(items: [])
	
	public init(items: Set<Item>) {
		self.items = items
	}
	
	public init(items: [Item]) {
		self.items = Set(items)
	}
	
	
	public mutating func append(_ other: Self) {
		self.items.formUnion(other.items)
	}
	
	public func appending(_ other: Self) -> Self {
		var newConfiguration = self
		newConfiguration.append(other)
		return newConfiguration
	}
	
	internal var stringValue: String {
		items.map(\.rawValue).sorted().joined(separator: ",")
	}
}

extension RowConfiguration: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: Item...) {
		self.init(items: Set(elements))
	}
}

extension RowConfiguration: CustomDebugStringConvertible {
	public var debugDescription: String { stringValue }
}
