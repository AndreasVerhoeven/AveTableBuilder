//
//  TableContent.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

/// This is a temporary object that is constructed for the sole purpose to get `SectionInfoWithRows`'s out of it.
/// We can't use protocols and generics, because the swift compiler sadly crashes a lot when
/// combining @resultBuilders with nested generics.
open class TableContent<ContainerType: AnyObject>: TableBuilderContent<ContainerType, SectionInfoWithRows<ContainerType>> {
	override func postInit() {
		super.postInit()
		
		items.forEach { item in
			item.sectionInfo.creators.append(self)
		}
	}
}

extension TableContent: RowModifyable {
	public func modifyRows(_ callback: (RowInfo<ContainerType>) -> Void) -> Self {
		items.forEach { item in
			item.rowInfos.forEach(callback)
		}
		return self
	}
}
