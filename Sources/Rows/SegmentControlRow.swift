//
//  SegmentControlRow.swift
//  Demo
//
//  Created by Andreas Verhoeven on 22/03/2023.
//

import UIKit
import AutoLayoutConvenience

extension Row {
	// A row with a switch
	open class SegmentControl: Row<ContainerType, RowCells.SegmentControlCell> {
		public typealias Cell = RowCells.SegmentControlCell
		
		public enum Mode {
			case regular
			case fullWidth
		}
		
		public convenience init<Collection: RandomAccessCollection>(
			_ data: Collection,
			binding: TableBinding<Collection.Element>,
			mode: Mode = .regular,
			segment: @escaping (Collection.Element) -> Any
		) where Collection.Element: Hashable {
			self.init(data, identifiedBy: { $0 }, binding: binding, mode: mode, segment: segment)
		}
		
		public init<Collection: RandomAccessCollection, ID: Hashable>(
			_ data: Collection,
			identifiedBy: @escaping (Collection.Element) -> ID,
			binding: TableBinding<ID>,
			mode: Mode = .regular,
			segment: @escaping (Collection.Element) -> Any
		) where Collection.Element: Hashable {
			super.init(cellClass: Cell.self, modifying: []) { container, cell, animated in
				cell.callback = { binding.wrappedValue = identifiedBy(data[data.index(data.startIndex, offsetBy: $0) ]) }
				cell.isFullWidth = mode == .fullWidth
				cell.segmentControl.removeAllSegments()

				for item in data {
					let value = segment(item)
					if let value = value as? String {
						cell.segmentControl.insertSegment(withTitle: value, at: cell.segmentControl.numberOfSegments, animated: false)
					} else if let value = value as? UIImage {
						cell.segmentControl.insertSegment(with: value, at: cell.segmentControl.numberOfSegments, animated: false)
					} else {
						cell.segmentControl.insertSegment(withTitle: nil, at: cell.segmentControl.numberOfSegments, animated: false)
					}
				}
				if let index = data.firstIndex(where: { binding.wrappedValue == identifiedBy($0) }) {
					cell.segmentControl.selectedSegmentIndex = data.distance(from: data.startIndex, to: index)
				} else {
					cell.segmentControl.selectedSegmentIndex = -1
				}
			}
			
			if mode == .fullWidth {
				backgroundColor(.clear)
			}
		}
	}
}

extension RowCells {
	public class SegmentControlCell: UITableViewCell {
		public let segmentControl = UISegmentedControl()
		
		public typealias Callback = (Int) -> Void
		public var callback: Callback?
		
		public var isFullWidth = false {
			didSet {
				segmentControl.activeConditionalConstraintsConfigurationName = isFullWidth ? .alternative : .main
			}
		}
		
		@objc private func valueChanged(_ sender: Any) {
			callback?(segmentControl.selectedSegmentIndex)
		}
		
		public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
			super.init(style: style, reuseIdentifier: reuseIdentifier)
			
			UIView.addNamedConditionalConfiguration(.main) {
				contentView.addSubview(segmentControl, filling: .readableContent)
			}
			UIView.addNamedConditionalConfiguration(.alternative) {
				contentView.addSubview(segmentControl, filling: .superview, insets: .vertical(2))
			}
			
			segmentControl.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
		}
		
		@available(*, unavailable)
		public required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
}
