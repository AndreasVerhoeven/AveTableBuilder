//
//  TableBinding.swift
//  Demo
//
//  Created by Andreas Verhoeven on 07/03/2023.
//

import Foundation

/// Can be used to bind to a value. Used by `TableState`. Nonmutating setter, so can be used
/// in nonmutating contexts.
@propertyWrapper public final class TableBinding<Value>: ChangeObservable {
	public let get: () -> Value
	public let set: (Value) -> Void
	
	/// private state
	private var state: TableState<Value>?
	private var internalObservers = ChangeObserverList<Value>()
	public var observers: ChangeObserverList<Value> { state?.observers ?? internalObservers }
	private var allowAnimatedUpdates = true
	
	/// updates to this binding trigger non-animated table updates
	public func noAnimatedUpdates() -> Self {
		allowAnimatedUpdates = false
		return self
	}
	
	/// initializer with a getter and setter.
	public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
		self.get = get
		self.set = set
	}
	
	/// initializer for a state
	public init(state: TableState<Value>) {
		self.state = state
		self.get = { state.wrappedValue }
		self.set = { state.wrappedValue = $0 }
	}
	
	/// returns the value we wrapped
	public var wrappedValue: Value {
		get { get() }
		set {
			TableBuilderStaticStorage.withAnimatedUpdates(suppressed: allowAnimatedUpdates == false) {
				let oldValue = wrappedValue
				set(newValue)
				if state == nil {
					notifyCallbacks(oldValue: oldValue, newValue: newValue)
				}
			}
		}
	}
	
	/// ourselves!
	public var projectedValue: TableBinding<Value> { self }
}

extension TableBinding {
	/// Creates a binding that has a getter and setter called with a specific container. The container is held weakly.
	public convenience init<ContainerType: AnyObject>(
		container: ContainerType,
		get: @escaping (_ `self`: ContainerType) -> Value,
		set: @escaping (_ `self`: ContainerType, _ value: Value) -> Void
	) {
		let originalValue = get(container)
		self.init(get: { [weak container] in
			guard let container else { return originalValue }
			return get(container)
		}, set: { [weak container] newValue in
			guard let container else { return }
			set(container, newValue)
		})
	}
	
	/// Creates a binding with a custom getter and setter with a specific container as parameter. The container is held weakly.
	public static func custom<ContainerType: AnyObject>(
		container: ContainerType,
		get: @escaping (_ `self`: ContainerType) -> Value,
		set: @escaping (_ `self`: ContainerType, _ value: Value) -> Void
	) -> TableBinding<Value> {
		return TableBinding(container: container, get: get, set: set)
	}
	
	/// Creates a binding to a key path of a container. The container hs held weakly.
	public static func keyPath<ContainerType: AnyObject>(_ container: ContainerType, _ keyPath: ReferenceWritableKeyPath<ContainerType, Value>) -> Self {
		return Self(container: container, keyPath: keyPath)
	}
	
	/// Creates a binding to a key path of a container. The container hs held weakly.
	public convenience init<ContainerType: AnyObject>(
		container: ContainerType,
		keyPath: ReferenceWritableKeyPath<ContainerType, Value>
	) {
		self.init(container: container, get: { $0[keyPath: keyPath] }, set: { $0[keyPath: keyPath] = $1 })
	}
}
extension TableBinding {
	/// Returns a binding where wrappedValue  is transformed by a callback
	public func transformed(_ transform: @escaping (Value) -> Value) -> Self {
		Self(get: { transform(self.wrappedValue) }, set: { self.wrappedValue = transform($0) })
	}
	
	/// Returns a binding where wrappedValue is transformed from and to a value, e.g.
	/// `TableBinding<Int>.transformed(from: { $0 == 10 }, to: { $0 ? 10 : 0 })`
	/// converts an integer to a boolean binding: if the integer is 10, then the value is true, if the value is true, then the integer will be 10, otherwise 0
	public func transformed<ReturnValue>(from: @escaping (Value) -> ReturnValue, to: @escaping (ReturnValue) -> Value) -> TableBinding<ReturnValue> {
		TableBinding<ReturnValue>(get: { from(self.wrappedValue) }, set: { self.wrappedValue = to($0) })
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
