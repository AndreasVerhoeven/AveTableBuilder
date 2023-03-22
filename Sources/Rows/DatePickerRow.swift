//
//  RowModifyable+Date.swift
//  Demo
//
//  Created by Andreas Verhoeven on 06/03/2023.
//

import UIKit
import AutoLayoutConvenience

extension Row {
	open class DatePicker: BaseDatePicker {
		public init(
			text: String,
			image: UIImage? = nil,
			style: DateFormatter.Style = .medium,
			date: Date?,
			fallback: String? = nil,
			callback: DateChangeCallback? = nil
		) {
			super.init(text: text, image: image, date: date, fallback: fallback, callback: callback)
			setField(\.dateStyle, value: style)
			setField(\.timeStyle, value: DateFormatter.Style.none)
		}
		
		public convenience init(
			text: String,
			image: UIImage? = nil,
			style: DateFormatter.Style = .medium,
			binding: TableBinding<Date?>,
			fallback: String? = nil
		) {
			self.init(text: text, image: image, style: style, date: binding.wrappedValue, fallback: fallback) { container, date in
				binding.wrappedValue = date
			}
		}
	}
	
	open class DateTimePicker: BaseDatePicker {
		public init(
			text: String,
			image: UIImage? = nil,
			dateStyle: DateFormatter.Style = .medium,
			timeStyle: DateFormatter.Style = .medium,
			date: Date?,
			fallback: String? = nil,
			callback: DateChangeCallback? = nil
		) {
			super.init(text: text, image: image, date: date, fallback: fallback, callback: callback)
			setField(\.dateStyle, value: dateStyle)
			setField(\.timeStyle, value: timeStyle)
		}
		
		public convenience init(
			text: String,
			image: UIImage? = nil,
			dateStyle: DateFormatter.Style = .medium,
			timeStyle: DateFormatter.Style = .medium,
			binding: TableBinding<Date?>,
			fallback: String? = nil
		) {
			self.init(text: text, image: image, dateStyle: dateStyle, timeStyle: timeStyle, date: binding.wrappedValue, fallback: fallback) { container, date in
				binding.wrappedValue = date
			}
		}
	}
	
	open class BaseDatePicker: Row<ContainerType, UITableViewCell> {
		public typealias DateChangeCallback = (_ `self`: ContainerType, _ date: Date) -> Void
		
		fileprivate init(text: String, image: UIImage? = nil, date: Date?, fallback: String? = nil, callback: DateChangeCallback? = nil) {
			super.init(style: .value1, modifying: [])
			_ = self.text(text).image(image).accessory(.disclosureIndicator)
			
			modifyRows { item in
				item.configurationHandlers.append { `container`, cell, animated, rowInfo in
					let configuration = rowInfo.dateRowConfiguration
					let detailText = date.flatMap { configuration.format($0) } ?? fallback
					cell.detailTextLabel?.setText(detailText, animated: animated)
				}
				
				item.selectionHandlers.append { container, tableView, indexPath, rowInfo in
					guard let controller = Self.closestViewController else { return }
					let configuration = rowInfo.dateRowConfiguration
					
					DatePickerViewController.show(configurationCallback: { picker in
						picker.date = date ?? Date()
						configuration.configure(datePicker: picker)
					}, changedCallback: { controller in
						callback?(container, controller.datePicker.date)
					}, dismissCallback: nil, in: controller, from: Self.currentCell)
				}
			}
		}
		
		@discardableResult public func calendar(_ calendar: Calendar?) -> Self {
			setField(\.calendar, value: calendar)
		}
		
		@discardableResult public func timezone(_ timezone: TimeZone?) -> Self {
			setField(\.timezone, value: timezone)
		}
		
		@discardableResult public func set(minimumDate: Date? = nil, maximumDate: Date? = nil) -> Self {
			setField(\.minimumDate, value: minimumDate).setField(\.maximumDate, value: maximumDate)
		}
		
		@discardableResult public func formatter(_ formatter: DateFormatter? = nil) -> Self {
			setField(\.formatter, value: formatter)
		}
		
		@discardableResult fileprivate func setField<T>(_ keyPath: WritableKeyPath<DatePickerConfiguration, T>, value: T) -> Self {
			_ = modifyRows { item in
				item.dateRowConfiguration[keyPath: keyPath] = value
			}
			return self
		}
	}
}

extension RowInfo {
	fileprivate var dateRowConfiguration: DatePickerConfiguration {
		get { storage.retrieve(key: "_dateRowConfiguration", default: .init()) }
		set { storage.store(newValue, key: "_dateRowConfiguration")  }
	}
}

fileprivate struct DatePickerConfiguration {
	var mode: UIDatePicker.Mode?
	var minimumDate: Date?
	var maximumDate: Date?
	var calendar: Calendar?
	var timezone: TimeZone?
	var formatter: DateFormatter?
	var dateStyle: DateFormatter.Style?
	var timeStyle: DateFormatter.Style?
	
	func configure(datePicker: UIDatePicker) {
		mode.flatMap { datePicker.datePickerMode = $0 }
		minimumDate.flatMap { datePicker.minimumDate = $0 }
		maximumDate.flatMap { datePicker.maximumDate = $0 }
		calendar.flatMap { datePicker.calendar = $0 }
		timezone.flatMap { datePicker.timeZone = $0 }
	}
	
	func format(_ date: Date) -> String? {
		if let formatter {
			return formatter.string(from: date)
		} else {
			return DateFormatter.localizedString(from: date, dateStyle: dateStyle ?? .medium, timeStyle: timeStyle ?? .medium)
		}
	}
}

fileprivate final class DatePickerViewController: UIViewController {
	let datePicker = UIDatePicker()
	
	typealias Callback = (DatePickerViewController) -> Void
	typealias ConfigurationCallback = (UIDatePicker) -> Void
	
	var datePickerChangedCallback: Callback?
	var dismissCallback: Callback?
	var configurationCallback: ConfigurationCallback?
	
	static func show(configurationCallback: @escaping ConfigurationCallback,
					 changedCallback: Callback?,
					 dismissCallback: Callback?,
					 in viewController: UIViewController,
					 from source: Any?) {
		let controller = DatePickerViewController()
		controller.configurationCallback = configurationCallback
		controller.datePickerChangedCallback = changedCallback
		controller.dismissCallback = dismissCallback
		
		controller.modalPresentationStyle = .popover
		controller.popoverPresentationController?.delegate = controller
		if let source = source as? UIBarButtonItem {
			controller.popoverPresentationController?.barButtonItem = source
		} else if let source = source as? UIView {
			controller.popoverPresentationController?.sourceView = source
		}
		viewController.present(controller, animated: true)
	}
	
	// MARK: - Input
	@objc private func datePickerChanged(_ sender: Any) {
		datePickerChangedCallback?(self)
	}
	
	// MARK: - UIViewController
	override func viewDidLoad() {
		datePicker.datePickerMode = .date
		if #available(iOS 14, *) {
			datePicker.preferredDatePickerStyle = .inline
		} else if #available(iOS 13.4, *) {
			datePicker.preferredDatePickerStyle = .wheels
		}
		
		configurationCallback?(datePicker)
		datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
		
		view.backgroundColor = .systemBackground
		view.addSubview(datePicker, filling: .superview)
	}
	
	override var preferredContentSize: CGSize {
		get { datePicker.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)) }
		set { super.preferredContentSize = newValue }
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		if presentingViewController == nil {
			dismissCallback?(self)
		}
	}
}

extension DatePickerViewController: UIPopoverPresentationControllerDelegate {
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		return .none
	}
}
