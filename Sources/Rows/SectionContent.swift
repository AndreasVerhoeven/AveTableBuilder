//
//  SectionContent.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 28/02/2023.
//

import UIKit
import UIKitAnimations

/// This is a temporary object that is constructed for the sole purpose to get `RowInfo`'s out of it.
/// We can't use protocols and generics, because the swift compiler sadly crashes a lot when
/// combining @resultBuilders with nested generics.
open class SectionContent<ContainerType: AnyObject>: TableBuilderContent<ContainerType, RowInfo<ContainerType>>, ProxiedTableBuilderStoreDelegate {
	
	public func reference(_ reference: TableItemReference) -> Self {
		modifyRows { item in
			item.references.append(reference)
		}
	}
	
	public func reference(_ reference: TableItemMultiReference) -> Self {
		TableBuilderStaticStorage.registerTableItemMultiReference(reference)
		
		modifyRows { item in
			let itemReference = TableItemReference()
			reference.wrappedValue[item.id.onlyLastPart] = itemReference
			item.references.append(itemReference)
		}
		return self
	}
	
	public var hasRows: Bool { items.isEmpty == false }
	public private(set) lazy var storage: TableBuilderStore = ProxiedTableBuilderStore(delegate: self)
	
	func proxiedStore<T>(_ value: T?, key: TableBuilderStore.Keys.Key<T>) {
		items.forEach { $0.storage.store(value, key: key) }
	}
	
	func proxiedRetrieve<T>(key: TableBuilderStore.Keys.Key<T>) -> T? {
		RowInfo<ContainerType>.current?.storage.retrieve(key: key)
	}
	
	override func postInit() {
		super.postInit()
		modifyRows { item in
			item.creators.append(self)
		}
	}
	
	public func adapt<OtherContainerType: AnyObject>(to type: OtherContainerType.Type, from originalContainer: ContainerType) -> RowCollection<OtherContainerType> {
		let items = self.items.map { $0.adapt(to: type, from: originalContainer) }
		return RowCollection(items: items)
	}
	
	public func bind<OtherContainerType: AnyObject>(_ originalContainer: ContainerType) -> RowCollection<OtherContainerType> {
		adapt(to: OtherContainerType.self, from: originalContainer)
	}
	
	public func identified<T: Hashable>(by id: T) -> Self {
		modifyRows { item in
			item.hasExplicitIdForForEach = true
			item.id.append(.custom(id))
		}
	}
}

extension SectionContent: RowModifyable {
	@discardableResult public func modifyRows(_ callback: (RowInfo<ContainerType>) -> Void) -> Self {
		items.forEach(callback)
		return self
	}
}
