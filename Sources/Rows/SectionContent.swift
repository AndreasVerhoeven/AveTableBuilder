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
open class SectionContent<ContainerType: AnyObject>: TableBuilderContent<ContainerType, RowInfo<ContainerType>> {
	public func reference(_ reference: TableItemReference) -> Self {
		modifyRows { item in
			item.reference.append(reference)
		}
	}
	
	/// store a piece of information that can be retrieve later in async callbacks from RowInfo
	public func storeRowData(_ key: RowInfo<ContainerType>.StorageKey, value: Any?) {
		items.forEach { $0.storage[key] = value }
	}
	
	/// this is only valid during callbacks initiated from RowInfo handlers
	static func retrieveRowData<T>(_ key: RowInfo<ContainerType>.StorageKey, as type: T.Type) -> T? {
		return Self.currentRowInfo?.storage[key] as? T
	}
	
	public func storeTableData(_ key: RowInfo<ContainerType>.StorageKey, value: Any?) {
		TableBuilder<ContainerType>.currentBuilder?.rowInfoStorage[key] = value
	}
	
	static func retrieveTableData<T>(_ key: RowInfo<ContainerType>.StorageKey, as type: T.Type) -> T? {
		TableBuilder<ContainerType>.currentBuilder?.rowInfoStorage[key] as? T
	}
}

extension SectionContent: RowModifyable {
	public func modifyRows(_ callback: (RowInfo<ContainerType>) -> Void) -> Self {
		items.forEach(callback)
		//items = items.map { callback($0) }
		return self
	}
}
