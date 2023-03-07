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
	
	/// Returns a binding where wrappedValue is transformed from and to a value, e.g.
	/// `TableBinding<Int>.transformed(from: { $0 == 10 }, to: { $0 ? 10 : 0 })`
	/// converts an integer to a boolean binding: if the integer is 10, then the value is true, if the value is true, then the integer will be 10, otherwise 0
	public func transformed<ReturnValue>(from: @escaping (Value) -> ReturnValue, to: @escaping (ReturnValue) -> Value) -> TableBinding<ReturnValue> {
		TableBinding<ReturnValue>(getValue: { from(self.wrappedValue) }, setValue: { self.wrappedValue = to($0) })
	}
	
	/// Converts any Equatable TableBinding to a true/false binding. E.g. `self.$integer.boolean(trueValue: 10, falseValue: 0)`
	public func boolean(trueValue: Value, falseValue: Value) -> TableBinding<Bool> where Value: Equatable {
		transformed(from: { $0 == trueValue }, to: { $0 ? trueValue : falseValue })
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
