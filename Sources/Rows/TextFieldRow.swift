//
//  TextFieldRow.swift
//  Demo
//
//  Created by Andreas Verhoeven on 11/03/2023.
//

import UIKit

extension Row {
	// A row with a switch
	open class TextField: Row<ContainerType, RowCells.TextFieldCell> {
		public typealias ChangeCallback = (_ `self`: ContainerType, _ value: String?) -> Void
		
		/// Creates a row with a switch with a value and a callback
		public init(text: String?, placeholder: String? = nil, change: ChangeCallback? = nil) {
			super.init(cellClass: RowCells.TextFieldCell.self) { container, cell, animated in
				if let change = change {
					cell.callback = { [weak container] value in
						guard let container else { return }
						change(container, value)
					}
				} else {
					cell.callback = nil
				}
				
				cell.textField.placeholder = placeholder
				if cell.textField.text != text {
					cell.textField.text = text
				}
			}
		}
		
		/// Creates a row with a switch with a binding
		public init(binding: TableBinding<String>, placeholder: String? = nil)  {
			super.init(cellClass: RowCells.TextFieldCell.self) { container, cell, animated in
				cell.callback = { binding.wrappedValue = $0 ?? "" }
				
				cell.textField.placeholder = placeholder
				let value = binding.wrappedValue
				if cell.textField.text != value {
					cell.textField.text = value
				}
			}
		}
	}
}

extension RowModifyable {
	@discardableResult public func onConfigureTextField(_ handler: @escaping (_ `self`: ContainerType, _ textField: UITextField) -> Void) -> Self {
		preConfigure(modifying: [.textField]) { container, cell, animated in
			guard let cell = cell as? RowCells.TextFieldCell else { return }
			handler(container, cell.textField)
		}
	}
}

extension RowCells {
	public class TextFieldCell: UITableViewCell, RowFirstResponderBecomeable {
		public let textField = UITextField()
		
		public typealias Callback = (String?) -> Void
		public var callback: Callback?
		
		@objc private func changed(_ sender: Any) {
			callback?(textField.text)
		}
		
		public func makeFirstResponder() -> Bool {
			textField.becomeFirstResponder()
		}
		
		public override func prepareForReuse() {
			super.prepareForReuse()
			callback = nil
		}
		
		public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
			super.init(style: style, reuseIdentifier: reuseIdentifier)
			
			textField.addTarget(self, action: #selector(changed(_:)), for: .editingChanged)
			contentView.addSubview(textField, filling: .layoutMargins)
		}
		
		@available(*, unavailable)
		public required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
}
