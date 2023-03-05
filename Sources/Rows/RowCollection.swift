//
//  RowCollection.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation


/// This is a Collection of Rows used in `@SectionTableBuilder`: it's the result of
/// every transformation.
open class RowCollection<ContainerType: AnyObject>: SectionContent<ContainerType> {
	public typealias InnerItem = RowInfo<ContainerType>
	public typealias BaseItem = SectionContent<ContainerType>
	
	public init(wrapping list: [BaseItem], id: TableItemIdentifier = .empty) {
		let items = list.flatMap { $0.items.map { $0.appending(id: id) } }
		super.init(items: items)
	}
	
	public init(_ other: [BaseItem]) {
		let items = other.enumerated().flatMap { (offset, item) in
			item.items.map { $0.appending(id: .offset(offset)) }
		}
		super.init(items: items)
	}
	
	public init(_ other: BaseItem?, id: TableItemIdentifier) {
		let items = other?.items.map { $0.appending(id: id) } ?? []
		super.init(items: items)
	}
}
