//
//  ChangeObserver.swift
//  Demo
//
//  Created by Andreas Verhoeven on 22/03/2023.
//

import Foundation

public class ChangeObserverList<Value> {
	fileprivate var registrations = [ChangeCallbackRegistration]()
	fileprivate var knownRegistrations = Set<AnyHashable>()
	
	public typealias ChangeCallback = (_ oldValue: Value, _ newValue: Value) -> Void
	fileprivate struct ChangeCallbackRegistration {
		var identifier: AnyHashable = AnyHashable(UUID())
		var callback: ChangeCallback
	}
	
	public func register(identifier: AnyHashable? = nil, callback: @escaping ChangeCallback) {
		if let identifier {
			guard knownRegistrations.contains(identifier) == false else { return }
			knownRegistrations.insert(identifier)
			registrations.append(.init(identifier: identifier, callback: callback))
		} else {
			registrations.append(.init(callback: callback))
		}
	}
	
	public func deregister(identifier: AnyHashable) {
		registrations.removeAll { $0.identifier ==  identifier }
		knownRegistrations.remove(identifier)
	}
	
	func notify(oldValue: Value, newValue: Value) {
		registrations.forEach { $0.callback(oldValue, newValue) }
	}
}

public protocol SimpleChangeObservable {
	func register(object: AnyObject, callback: @escaping () -> Void)
	func deregister(object: AnyObject)
}

public protocol ChangeObservable: SimpleChangeObservable {
	associatedtype Value
	var observers: ChangeObserverList<Value> { get }
	
	func notifyCallbacks(oldValue: Value, newValue: Value)
}

extension ChangeObservable where Value: Equatable {
	public func notifyCallbacks(oldValue: Value, newValue: Value) {
		guard oldValue != newValue else { return }
		notifyCallbacks(oldValue: oldValue, newValue: newValue)
	}
}

extension ChangeObservable {
	public func notifyCallbacks(oldValue: Value, newValue: Value) {
		observers.notify(oldValue: oldValue, newValue: newValue)
	}
}

extension ChangeObservable {
	public typealias ChangeCallback = ChangeObserverList<Value>.ChangeCallback
	public func onChange(_ callback: @escaping ChangeCallback) {
		observers.register(callback: callback)
	}
	
	public func onChange(_ callback: @escaping (_ newValue: Value) -> Void) {
		onChange { _, newValue in callback(newValue) }
	}
	
	public func onChange(_ callback: @escaping () -> Void) {
		onChange { _, _ in callback() }
	}
	
	public func register<T: AnyObject>(for object: T, callback: @escaping ChangeCallback) {
		observers.register(identifier: AnyHashable(ObjectIdentifier(object)), callback: callback)
	}
	
	public func deregister<T: AnyObject>(for object: T) {
		observers.deregister(identifier: AnyHashable(ObjectIdentifier(object)))
	}
	
	public func register(object: AnyObject, callback: @escaping () -> Void) {
		register(for: object, callback: { _, _ in callback() })
	}
	
	public func deregister(object: AnyObject) {
		deregister(for: object)
	}
}

