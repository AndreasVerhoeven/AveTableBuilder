//
//  TableBuilderContent.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

/// base class for the temporary objects that are constructed in our @resultBuilders to get
/// items out of them with identifiers.
/// We can't use protocols and generics, because the swift compiler sadly crashes a lot when
/// combining @resultBuilders with nested generics, so we need to use a class hierarchy.
public class TableBuilderContent<ContainerType, Item: IdentifiableTableItem> {
	public var items = [Item]()
	
	public init(items: [Item] = [Item]()) {
		self.items = items
	}
	
	public init(item: Item) {
		self.items = [item]
	}
}
