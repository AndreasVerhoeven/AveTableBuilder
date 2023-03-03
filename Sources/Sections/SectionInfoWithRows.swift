//
//  SectionInfoWithRows.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

/// This is the end result of Table Building for each section: info on the section and a list of rows in that section
public struct SectionInfoWithRows<ContainerType>: IdentifiableTableItem {
	public var id: TableItemIdentifier {
		get { sectionInfo.id }
		set { sectionInfo.id = newValue }
	}
	
	public var sectionInfo: SectionInfo<ContainerType>
	public var rowInfos: [RowInfo<ContainerType>]
}
