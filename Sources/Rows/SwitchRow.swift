//
//  SwitchRow.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit

extension Row {
	// A row with a switch
	public class Switch: Row<ContainerType, Switch.Cell> {
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
			}
			
			@available(*, unavailable)
			public required init?(coder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
		}
		
		public typealias ChangeCallback = (_ `self`: ContainerType, _ isOn: Bool) -> Void
		
		/// Creates a row with a switch with a value and a callback
		public init(text: String?, image: UIImage? = nil, isOn: Bool, change: ChangeCallback? = nil) {
			super.init(cellClass: Cell.self) { container, cell, animated in
				cell.textLabel?.setText(text, animated: animated)
				cell.imageView?.setImage(image, animated: animated)
				if let change = change {
					cell.callback = { [weak container] isOn in
						guard let container else { return }
						change(container, isOn)
					}
				} else {
					cell.callback = nil
				}
				cell.switchControl.setOn(isOn, animated: animated)
			}
		}
		
		/// Creates a row with a switch with a binding
		public init(text: String?, image: UIImage? = nil, binding: TableBinding<Bool>)  {
			super.init(cellClass: Cell.self) { container, cell, animated in
				cell.textLabel?.setText(text, animated: animated)
				cell.imageView?.setImage(image, animated: animated)
				cell.callback = { binding.wrappedValue = $0 }
				cell.switchControl.setOn(binding.wrappedValue, animated: animated)
			}
		}
	}
}
