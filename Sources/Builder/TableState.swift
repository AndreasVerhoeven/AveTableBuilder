//
//  TableState.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

/// Protocol for items being
internal protocol TableUpdatable {
	func update(animated: Bool)
}

/// Protocols for items that can notify for updates
public protocol TableUpdateNotifyable {
	/// callback will be called when the conforming items updates
	func onChange(_ callback: @escaping () -> Void)
}

/// Property wrapper that keeps state used in a Table.
@propertyWrapper public struct TableState<Value>: TableUpdateNotifyable {
	/// We store our value and callbacks in a class, so we can update bindings and
	/// callbacks without mutating self.
	private class Storage {
		var value: Value
		var onChangeCallbacks = [() -> Void]()
		init(initialValue: Value) { self.value = initialValue }
	}
	private var storage: Storage
	
	public func onChange(_ callback: @escaping () -> Void) {
		storage.onChangeCallbacks.append(callback)
	}
	
	public var wrappedValue: Value {
		get { self.storage.value }
		nonmutating set {
			self.storage.value = newValue
			storage.onChangeCallbacks.forEach { $0() }
		}
	}
	
	public init(wrappedValue value: Value) {
		self.storage = Storage(initialValue: value)
	}
	
	/// returns a binding that can be used to read/write to this TableState
	public var projectedValue: TableBinding<Value> {
		TableBinding(getValue: { self.wrappedValue }, setValue: { self.wrappedValue = $0 })
	}
}


/// Can be used to bind to a value. Used by `TableState`. Nonmutating setter, so can be used
/// in nonmutating contexts.
@propertyWrapper public struct TableBinding<Value> {
	public var wrappedValue: Value {
		get { return getValue() }
		nonmutating set { setValue(newValue) }
	}
	
	public let getValue: () -> Value
	public let setValue: (Value) -> Void
	
	public init(getValue: @escaping () -> Value, setValue: @escaping (Value) -> Void) {
		self.getValue = getValue
		self.setValue = setValue
	}
	
	public var projectedValue: Self { self }
}
