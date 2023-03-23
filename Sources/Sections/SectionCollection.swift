//
//  SectionCollection.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

/// This is a Collection of Sections used in `@TableContentBuilder`: it's the result of
/// every transformation.
public class SectionCollection<ContainerType: AnyObject>: TableContent<ContainerType> {
	public typealias InnerItem = SectionInfoWithRows<ContainerType>
	public typealias BaseItem = TableContent<ContainerType>
	
	public init(_ other: [BaseItem]) {
		let items = other.enumerated().flatMap { (offset, item) in
			item.items.map { $0.appending(id: .offset(offset)) }
		}
		super.init(items: items)
	}
	
	public init(forArray other: [BaseItem]) {
		let items = other.enumerated().flatMap { (offset, item) in
			item.items.map { item in
				defer { item.sectionInfo.hasExplicitIdForForEach = false }
				return item.sectionInfo.hasExplicitIdForForEach ? item : item.appending(id: .offset(offset))
			}
		}
		super.init(items: items)
	}
	
	public init(_ other: BaseItem?, id: TableItemIdentifier) {
		let items = other?.items.map { $0.appending(id: id) } ?? []
		super.init(items: items)
	}
	
	override internal init(items: [InnerItem]) {
		super.init(items: items)
	}
}
