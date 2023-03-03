//
//  StepperRow.swift
//  Demo
//
//  Created by Andreas Verhoeven on 03/03/2023.
//

import UIKit
import AutoLayoutConvenience
import AveFontHelpers

extension Row {
	// A row with a switch
	public class Stepper: Row<ContainerType, Stepper.Cell> {
		public class Cell: UITableViewCell {
			public let stepper = UIStepper()
			public let label = UILabel(font: .from(.ios.body), color: .secondaryLabel)
			public let stackView = UIStackView(axis: .horizontal, spacing: 8)
			
			public typealias Callback = (Double) -> Void
			public var callback: Callback?
			
			@objc private func valueChanged(_ sender: Any) {
				callback?(stepper.value)
			}
			
			public func setValue(_ value: Double, animated: Bool) {
				stepper.value = Double(value)
				label.setText(NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal))
				stackView.frame.size = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
				accessoryView = stackView
			}
			
			public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
				super.init(style: style, reuseIdentifier: reuseIdentifier)
				
				stepper.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
				stackView.addArrangedSubviews([label, stepper])
				setValue(0, animated: false)
			}
			
			@available(*, unavailable)
			public required init?(coder: NSCoder) {
				fatalError("init(coder:) has not been implemented")
			}
		}
		
		/// Creates a row with a switch with a binding
		public init(text: String?, binding: TableBinding<Int>)  {
			super.init(cellClass: Cell.self) { container, cell, animated in
				cell.textLabel?.setText(text, animated: animated)
				cell.callback = { binding.wrappedValue = Int($0) }
				cell.setValue(Double(binding.wrappedValue), animated: animated)
			}
		}
	}
}
