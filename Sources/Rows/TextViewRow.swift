//
//  TextViewRow.swift
//  Demo
//
//  Created by Andreas Verhoeven on 27/03/2023.
//

import UIKit
import AutoLayoutConvenience

extension Row {
	// A row with a switch
	open class TextView: Row<ContainerType, RowCells.TextViewCell> {
		public typealias ChangeCallback = (_ `self`: ContainerType, _ value: String?) -> Void
		
		/// Creates a row with a switch with a value and a callback
		public init(text: String?, placeholder: String? = nil, change: ChangeCallback? = nil) {
			super.init(cellClass: RowCells.TextViewCell.self)
			
			modifyRows{ row in
				row.addingConfigurationHandler(modifying: []) { container, cell, animated, rowInfo in
					guard let cell = cell as? RowCells.TextViewCell else { return }
					rowInfo.storage.isInUpdate = true
					
					let storage = rowInfo.storage
					DispatchQueue.main.async { [weak storage] in
						storage?.isInUpdate = false
					}
					
					if let change = change {
						cell.callback = { [weak container] value in
							guard let container else { return }
							change(container, value)
						}
					} else {
						cell.callback = nil
					}
					
					let updater = TableBuilderStaticStorage.currentUpdater
					
					
					cell.textView.contentSizeInvalidatedCallback = { [weak storage] _ in
						guard storage?.isInUpdate == false else { return }
						storage?.isInUpdate = true
						defer { storage?.isInUpdate = false }
						updater?.update(animated: true)
					}
					cell.textView.placeholder = placeholder
					if cell.textView.text != text {
						cell.textView.text = text
					}
				}
			}
		}
		
		/// Creates a row with a switch with a binding
		public convenience init(binding: TableBinding<String>, placeholder: String? = nil)  {
			self.init(text: binding.wrappedValue, placeholder: placeholder, change: { container, value in
				binding.wrappedValue = value ?? ""
			})
		}
	}
	
	@discardableResult public func maximumNumberOfDisplayedLines(_ value: Int?) -> Self {
		onConfigureTextView { container, textView in
			let textHeight = value.flatMap { ceil(CGFloat(textView.font?.lineHeight ?? 0)) * CGFloat($0) } ?? 0
			textView.maximumHeight = textHeight + textView.textContainerInset.top + textView.textContainerInset.bottom
		}
	}
	
	@discardableResult public func maximumHeight(_ value: CGFloat?) -> Self {
		onConfigureTextView { container, textView in
			textView.maximumHeight = value ?? 0
		}
	}
}

extension RowModifyable {
	@discardableResult public func onConfigureTextView(_ handler: @escaping (_ `self`: ContainerType, _ textView: AutoSizingTextView) -> Void) -> Self {
		preConfigure(modifying: [.textField]) { container, cell, animated in
			guard let cell = cell as? RowCells.TextViewCell else { return }
			handler(container, cell.textView)
		}
	}
}

extension RowCells {
	public class TextViewCell: UITableViewCell, UITextViewDelegate, RowFirstResponderBecomeable {
		public let textView = AutoSizingTextView()
		
		public typealias Callback = (String?) -> Void
		public var callback: Callback?
		private var isInCallback = false
		
		public func textViewDidChange(_ textView: UITextView) {
			guard isInCallback == false else { return }
			isInCallback = true
			defer { isInCallback = false }
			callback?(textView.text)
		}
		
		public func makeFirstResponder() -> Bool {
			textView.becomeFirstResponder()
		}
		
		public override func prepareForReuse() {
			super.prepareForReuse()
			callback = nil
		}
		
		public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
			super.touchesBegan(touches, with: event)
			textView.becomeFirstResponder()
		}
		
		public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
			super.init(style: style, reuseIdentifier: reuseIdentifier)
			
			textView.font = .preferredFont(forTextStyle: .body)
			textView.backgroundColor = nil
			textView.delegate = self
			contentView.addSubview(textView, filling: .horizontally(.layoutMargins, vertically: .superview))
		}
		
		@available(*, unavailable)
		public required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
}

extension TableBuilderStore.Keys {
	fileprivate var isInUpdate: Key<Bool> { "_textViewIsInUpdate" }
}
