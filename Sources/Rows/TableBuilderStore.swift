//
//  TableBuilderStore.swift
//  Demo
//
//  Created by Andreas Verhoeven on 21/03/2023.
//

import UIKit

public final class TableBuilderStore {
	fileprivate var values = [Key: Any]()
	fileprivate var parent: TableBuilderStore?
	
	func chain(to parent: TableBuilderStore) {
		self.parent = parent
	}
	
	func store<T>(_ value: T?, key: Key) {
		values[key] = value
	}
	
	func retrieve<T>(key: Key, as type: T.Type) -> T? {
		return (values[key] as? T) ?? parent?.retrieve(key: key, as: type)
	}
	
	func modify<T>(key: Key, default defaultValue: T, handler: (_ value: inout T) -> Void) {
		var value = retrieve(key: key, as: T.self) ?? defaultValue
		handler(&value)
		store(value, key: key)
	}
	
	public struct Key: RawRepresentable, Hashable {
		public var rawValue: String
		
		public init(rawValue: String) {
			self.rawValue = rawValue
		}
	}
	
	func merge(from other: TableBuilderStore) {
		for (key, value) in other.values where values[key] == nil {
			values[key] = value
		}
	}
}
