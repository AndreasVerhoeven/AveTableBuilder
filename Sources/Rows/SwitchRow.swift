//
//  SwitchRow.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit

extension Row {
	// A row with a switch
	open class Switch: Row<ContainerType, RowCells.Cell> {
		public typealias Cell = RowCells.Cell
		
		public typealias ChangeCallback = (_ `self`: ContainerType, _ isOn: Bool) -> Void
		
		/// Creates a row with a switch with a value and a callback
		public init(text: String?, image: UIImage? = nil, isOn: Bool, change: ChangeCallback? = nil) {
			super.init(cellClass: Cell.self)
			
			modifyRows { item in
				item.addingConfigurationHandler(modifying: [.detailTextAlpha]) { container, cell, animated, rowInfo in
					guard let cell = cell as? Cell else { return }
					
					if let change = change {
						cell.callback = { [weak container] isOn in
							guard let container else { return }
							change(container, isOn)
						}
					} else {
						cell.callback = nil
					}
					
					UIView.performAnimationsIfNeeded(animated: animated) {
						cell.switchControl.isEnabled = rowInfo.storage.isEnabled ?? true
						cell.textLabel?.alpha = cell.switchControl.isEnabled ? 1 : 0.5
					}
					cell.switchControl.setOn(isOn, animated: animated)
				}
			}
			
			_ = self.text(text).image(image)
		}
		
		/// Creates a row with a switch with a binding
		public convenience init(text: String?, image: UIImage? = nil, binding: TableBinding<Bool>)  {
			self.init(text: text, image: image, isOn: binding.wrappedValue) { container, isOn in
				binding.wrappedValue = isOn
			}
		}
		
		public func isEnabled(_ enabled: Bool) -> Self {
			store(enabled, key: "switchIsEnabled")
			return self
		}
	}
}

extension TableBuilderStore.Keys {
	fileprivate var isEnabled: Key<Bool> { "switchIsEnabled" }
}

extension RowCells {
	public class Cell: UITableViewCell {
		public let switchControl = UISwitch()
		
		public typealias Callback = (Bool) -> Void
		public var callback: Callback?
		
		@objc private func toggled(_ sender: Any) {
			callback?(switchControl.isOn)
		}
		
		public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
			super.init(style: style, reuseIdentifier: reuseIdentifier)
			
			switchControl.addTarget(self, action: #selector(toggled(_:)), for: .valueChanged)
			accessoryView = switchControl
			editingAccessoryView = switchControl
		}
		
		@available(*, unavailable)
		public required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
}
