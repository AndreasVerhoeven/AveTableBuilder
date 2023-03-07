//
//  TableBinding.swift
//  Demo
//
//  Created by Andreas Verhoeven on 07/03/2023.
//

import Foundation

/// Can be used to bind to a value. Used by `TableState`. Nonmutating setter, so can be used
/// in nonmutating contexts.
@propertyWrapper public struct TableBinding<Value>: TableUpdateNotifyable {
	public var wrappedValue: Value {
		get { return getValue() }
		nonmutating set {
			setValue(newValue)
			storage.onChangeCallbacks.forEach { $0(newValue) }
		}
	}
	
	public let getValue: () -> Value
	public let setValue: (Value) -> Void
	
	public init(getValue: @escaping () -> Value, setValue: @escaping (Value) -> Void) {
		self.getValue = getValue
		self.setValue = setValue
	}
	
	public var projectedValue: Self { self }
	
	/// We store our value and callbacks in a class, so we can update bindings and
	/// callbacks without mutating self.
	private class Storage {
		var onChangeCallbacks = [(Value) -> Void]()
	}
	private var storage = Storage()
	
	public func onChange(_ callback: @escaping () -> Void) {
		storage.onChangeCallbacks.append({ _ in callback() })
	}
	
	public func onChange(_ callback: @escaping (Value) -> Void) {
		storage.onChangeCallbacks.append(callback)
	}
}

extension TableBinding {
	/// Returns a binding where wrappedValue  is transformed by a callback
	public func transformed(_ transform: @escaping (Value) -> Value) -> Self {
		Self(getValue: { transform(self.wrappedValue) }, setValue: { self.wrappedValue = transform($0) })
	}
}

extension TableBinding where Value == Bool {
	/// Returns a binding where false == true and true == false
	public var inverted: Self { transformed { !$0 } }
}

extension TableBinding where Value: SetAlgebra & Sequence {
	/// Returns a binding where the selection state is inverted with respect to a full sequence
	public func inverted<C: Sequence>(with full: C) -> Self where C.Element == Value.Element, C.Element: Hashable {
		return self.transformed { Value(full).subtracting($0) }
	}
}
