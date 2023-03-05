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
		modifyRows { row in
			var item = row
			item.reference.append(reference)
			return item
		}
	}
	
	/// store a piece of information that can be retrieve later in async callbacks from RowInfo
	public func store(_ key: RowInfo<ContainerType>.StorageKey, value: Any?) {
		items.forEach { $0.storage[key] = value }
	}
	
	/// this is only valid during callbacks initiated from RowInfo handlers
	static func retrieve<T>(_ key: RowInfo<ContainerType>.StorageKey, as type: T.Type) -> T? {
		return Self.currentRowInfo?.storage[key] as? T
	}
}

extension SectionContent: RowModifyable {
	public func modifyRows(_ callback: (RowInfo<ContainerType>) -> RowInfo<ContainerType>) -> Self {
		items = items.map { callback($0) }
		return self
	}
}
