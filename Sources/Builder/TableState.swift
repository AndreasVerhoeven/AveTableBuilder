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

/// Property wrapper that keeps state used in a Table.
@propertyWrapper public final class TableState<Value>: ChangeObservable {
	private var value: Value
	public var observers = ChangeObserverList<Value>()
	
	public var wrappedValue: Value {
		get { value }
		set {
			let oldValue = value
			value = newValue
			notifyCallbacks(oldValue: oldValue, newValue: newValue)
		}
	}
	
	public init(wrappedValue value: Value) {
		self.value = value
	}
	
	public var projectedValue: TableBinding<Value> {
		return TableBinding(state: self)
	}
}
