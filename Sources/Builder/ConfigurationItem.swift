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
		static let backgroundColor = Self(rawValue: "_backgroundColor")
		static let accessory = Self(rawValue: "_accessory")
		
		// content
		static let image = Self(rawValue: "_image")
		static let text = Self(rawValue: "_text")
		static let detailText = Self(rawValue: "_detailText")
		static let accessoryText = Self(rawValue: "_accessoryText")
		
		// content configuration
		static let textFont = Self(rawValue: "_textFont")
		static let detailTextFont = Self(rawValue: "_detailTextFont")
		static let accessoryTextFont = Self(rawValue: "_accessoryTextFont")
		
		static let textColor = Self(rawValue: "_textColor")
		static let detailTextColor = Self(rawValue: "_detailTextColor")
		static let accessoryTextColor = Self(rawValue: "_accessoryTextColor")
		
		static let textAlignment = Self(rawValue: "_textAlignment")
		static let detailTextAlignment = Self(rawValue: "_detailTextAlignment")
		static let accessoryTextAlignment = Self(rawValue: "_accessoryTextAlignment")
		
		static let imageTintColor = Self(rawValue: "_imageTintColor")
		static let numberOfLines = Self(rawValue: "_numberOfLines")
		
		// indicates that this row is manually configured: it's up
		// to the programmer to make things consistent
		static let manual = Self(rawValue: "_manual")
		
		// custom items for convenience
		static let custom1 = Self(rawValue: "_custom1")
		static let custom2 = Self(rawValue: "_custom2")
		static let custom3 = Self(rawValue: "_custom3")
		static let custom4 = Self(rawValue: "_custom4")
		static let custom5 = Self(rawValue: "_custom5")
		
		static func custom(_ name: String) -> Self {
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
