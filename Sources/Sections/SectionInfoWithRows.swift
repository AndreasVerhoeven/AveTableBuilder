//
//  SectionInfoWithRows.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import Foundation

/// This is the end result of Table Building for each section: info on the section and a list of rows in that section
public class SectionInfoWithRows<ContainerType: AnyObject>: IdentifiableTableItem {
	public var id: TableItemIdentifier {
		get { sectionInfo.id }
		set { sectionInfo.id = newValue }
	}
	
	public var sectionInfo: SectionInfo<ContainerType>
	public var rowInfos: [RowInfo<ContainerType>]
	
	public init(sectionInfo: SectionInfo<ContainerType>, rowInfos: [RowInfo<ContainerType>]) {
		self.sectionInfo = sectionInfo
		self.rowInfos = rowInfos
	}
	
	func adapt<OtherContainerType: AnyObject>(to type: OtherContainerType.Type, from originalContainer: ContainerType) -> SectionInfoWithRows<OtherContainerType> {
		let sectionInfo = self.sectionInfo.adapt(to: type, from: originalContainer)
		let rowInfos = self.rowInfos.map { $0.adapt(to: type, from: originalContainer) }
		return SectionInfoWithRows<OtherContainerType>(sectionInfo: sectionInfo, rowInfos: rowInfos)
	}
}
