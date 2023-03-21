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
	
	public func store<T>(_ value: T?, key: TableBuilderStore.Keys.Key<T>) {
		items.forEach { $0.storage.store(value, key: key) }
	}
	
	override func postInit() {
		super.postInit()
		modifyRows { item in
			item.creators.append(self)
		}
	}
}

extension SectionContent: RowModifyable {
	@discardableResult public func modifyRows(_ callback: (RowInfo<ContainerType>) -> Void) -> Self {
		items.forEach(callback)
		return self
	}
}
