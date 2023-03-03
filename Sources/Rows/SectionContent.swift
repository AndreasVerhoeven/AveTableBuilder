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
public class SectionContent<ContainerType>: TableBuilderContent<ContainerType, RowInfo<ContainerType>> {
	public func reference(_ reference: TableItemReference) -> Self {
		modifyRows { row in
			var item = row
			item.reference.append(reference)
			return item
		}
	}
}

extension SectionContent: RowModifyable {
	public func modifyRows(_ callback: (RowInfo<ContainerType>) -> RowInfo<ContainerType>) -> Self {
		items = items.map { callback($0) }
		return self
	}
}
