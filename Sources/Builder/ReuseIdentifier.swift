//
//  ReuseIdentifier.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 02/03/2023.
//

import UIKit

/// This is a ReuseIdentifier used to make a unique reuseIdentifier for cells based
/// on the cell class, style and which modifications have been applied.
///
/// By adding the modifications into the reuse identifier, we can ensure
/// that  re-used cells will always apply the modifications. Consider the following:
///
/// ```
/// 	Section {
///   		Row(text: "A").backgroundColor(.red)
///   		Row(text: "B").accessory(.disclosureIndicator)
/// 	}
/// ```
/// - Row "A" configures its backgroundColor
/// - Row "B" doesn't.
///
/// If Row "A" and Row "B" would re-use the same cells, B might reuse a
/// cell that used to be A and thus have a background color. Since B
/// doesn't do anything to the background color, it would suddenly
/// have a red background color.
///
/// There are two solutions to this problem:
/// 	1) always reset all properties on each re-use
///		2) keep cells apart that don't configure the same things
///
///	Solution 1) doesn't know how to reset the configuration of
///	custom cells, so its harder to get right.
///
///	Solution 2) is easy: just make sure different configured cells
///	have a different reuse-identifier.
///
/// We've picked solution 2. All the built-in modifiers
/// supply a list of things they modify and they get added to the
/// reuse-identifier.
public struct ReuseIdentifier {
	internal var cellClass: UITableViewCell.Type
	internal var cellStyle: UITableViewCell.CellStyle
	internal var modifications: RowConfiguration
	internal var fixedId: TableItemIdentifier?
	
	public var stringValue: String {
		var value = "\(NSStringFromClass(cellClass)).style=\(String(cellStyle.rawValue)).modifications=\(modifications.stringValue)"
		if let fixedId {
			value += ".fixedId=\(fixedId.stringValue)"
		}
		return value
	}
}

extension ReuseIdentifier: CustomDebugStringConvertible {
	public var debugDescription: String { stringValue }
}
