//
//  TableBuilderStore.swift
//  Demo
//
//  Created by Andreas Verhoeven on 21/03/2023.
//

import UIKit

/// This is dynamic storage to be able to add data to RowInfo, SectionInfo and TableBuilder dynamically.
/// Keys for storage are of the type `Keys.Key` and contain the type of data stored for the key:
///
///	```
///	extension TableBuilderStore.Keys.Key {
///		var myStringValue: Key<String> { "myStringValue" }
///		var myIntValue: Key<Int> { "myIntValue" }
///		var myStruct: Key<MyStruct> { "myStruct" }
///	}
///
///  rowInfo.storage.myStringValue = "X"
///  let string = rowInfo.storage.myStringValue // type is String?
///
///	```
/// Another way is to use store and retrieve together:
///
/// ```
/// extension RowInfo {
/// 	var myField: MyStruct {
/// 		get { retrieve("myField", default: .init()) }
/// 		set { store(newValue, "myField") }
/// 	}
/// }
///
/// print(rowInfo.myField.someProperty)
/// ```
///
@dynamicMemberLookup public final class TableBuilderStore {
	fileprivate var values = [String: Any]()
	fileprivate var parent: TableBuilderStore?
	
	func chain(to parent: TableBuilderStore) {
		self.parent = parent
	}
	
	subscript<T>(dynamicMember keyPath: KeyPath<Keys, Keys.Key<T>>) -> T? {
		get { retrieve(key: Keys.instance[keyPath: keyPath]) }
		set { store(newValue, key: Keys.instance[keyPath: keyPath]) }
	}
	
	func store<T>(_ value: T?, key: Keys.Key<T>) {
		values[key.rawValue] = value
	}
	
	func retrieve<T>(key: Keys.Key<T>) -> T? {
		return key.from(values[key.rawValue] ?? parent?.values[key.rawValue])
	}
	
	func retrieve<T>(key: Keys.Key<T>, default defaultValue: @autoclosure () -> T) -> T {
		if let value = retrieve(key: key) {
			return value
		} else {
			let value = defaultValue()
			store(value, key: key)
			return value
		}
	}
	
	func modify<T>(key: Keys.Key<T>, default defaultValue: T, callback: (inout T) -> Void) {
		var value = retrieve(key: key) ?? defaultValue
		callback(&value)
		store(value, key: key)
	}
	
	func merge(from other: TableBuilderStore) {
		for (key, value) in other.values where values[key] == nil {
			values[key] = value
		}
	}
}

extension TableBuilderStore {
	public struct Keys {
		fileprivate static var instance = Self()
		
		
		public struct Key<T>: RawRepresentable, ExpressibleByStringLiteral {
			public var rawValue: String
			
			public init(rawValue: String) {
				self.rawValue = rawValue
			}
			
			public init(stringLiteral value: StringLiteralType) {
				self.init(rawValue: value)
			}
			
			func from(_ value: Any?) -> T? { value as? T }
		}
		
	}
}
