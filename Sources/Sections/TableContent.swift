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
public class TableContent<ContainerType>: TableBuilderContent<ContainerType, SectionInfoWithRows<ContainerType>> {
}

extension TableContent: RowModifyable {
	public func modifyRows(_ callback: (RowInfo<ContainerType>) -> RowInfo<ContainerType>) -> Self {
		items = items.map { item in
			var newItem = item
			newItem.rowInfos = newItem.rowInfos.map { callback($0) }
			return newItem
		}
		return self
	}
}
