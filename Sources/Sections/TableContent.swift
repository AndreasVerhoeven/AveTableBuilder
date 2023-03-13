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
	
	/// stores a piece of information that can be retrieved later in async SectionInfo callback.
	public func storeSectionData(_ key: SectionInfo<ContainerType>.StorageKey, value: Any?) {
		items.forEach { $0.sectionInfo.storage[key] = value }
	}
	
	/// this is only valid during callbacks initiated from SectinInfo handlers
	static func retrieveSectionData<T>(_ key: SectionInfo<ContainerType>.StorageKey, as type: T.Type) -> T? {
		return Self.currentSectionInfo?.storage[key] as? T
	}
	
	public func storeTableData(_ key: SectionInfo<ContainerType>.StorageKey, value: Any?) {
		TableBuilder<ContainerType>.currentBuilder?.sectionInfoStorage[key] = value
	}
	
	static func retrieveTableData<T>(_ key: SectionInfo<ContainerType>.StorageKey, as type: T.Type) -> T? {
		TableBuilder<ContainerType>.currentBuilder?.sectionInfoStorage[key] as? T
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
