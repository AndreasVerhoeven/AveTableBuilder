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
	
	public var hasSections: Bool { items.isEmpty == false }
	
	public func adapt<OtherContainerType: AnyObject>(to type: OtherContainerType.Type, from originalContainer: ContainerType) -> SectionCollection<OtherContainerType> {
		let items = self.items.map { $0.adapt(to: type, from: originalContainer) }
		return SectionCollection(items: items)
	}
	
	public func bind<OtherContainerType: AnyObject>(_ originalContainer: ContainerType) -> SectionCollection<OtherContainerType> {
		adapt(to: OtherContainerType.self, from: originalContainer)
	}
	
	public func identified<T: Hashable>(by id: T) -> Self {
		for item in items {
			item.sectionInfo.hasExplicitIdForForEach = true
			item.id.append(.custom(id))
		}
		return self
	}
	
	
	public func emptySectionRemoved() -> Self {
		items.removeAll { $0.rowInfos.isEmpty }
		return self
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
