//
//  CustomViewRow.swift
//  Demo
//
//  Created by Andreas Verhoeven on 07/03/2023.
//

import UIKit
import AutoLayoutConvenience

extension Row {
	open class CustomView: Static {
		public init<View: UIView>(
			viewClass: View.Type = UIView.self,
			creation: ((_ `self`: ContainerType) -> View)? = nil,
			configure: @escaping (_ `self`: ContainerType, _ view: View, _ animated: Bool) -> Void
		) {
			super.init(cellClass: CustomViewCell.self, initial: { container, cell in
				let view = creation?(container) ?? View.init(frame: .zero)
				cell.addCustomViewTo = RowInfo<ContainerType>.current?.tableStorage.filling ?? .superview
				cell.customView = view
				configure(container, view, false)
				
			}) { container, cell, animated in
				guard let view = cell.customView as? View else {return }
				configure(container, view, animated)
			}
		}
		
		public convenience init<View: UIView>(
			viewClass: View.Type = UIView.self,
			creation: ((_ `self`: ContainerType) -> View)? = nil
		) {
			self.init(viewClass: viewClass, creation: creation, configure: { container, view, animated in })
		}
		
		@discardableResult public func filling(_ boxLayout: BoxLayout) -> Self {
			storage.filling = boxLayout
			return self
		}
	}
}

extension TableBuilderStore.Keys {
	fileprivate var filling: Key<BoxLayout> { "_customView.FillingContentView" }
}

fileprivate class CustomViewCell: UITableViewCell {
	var addCustomViewTo: BoxLayout = .superview
	
	var customView: UIView? {
		didSet {
			guard customView !== oldValue else { return }
			customView?.removeFromSuperview()
			guard let customView else { return }
			contentView.addSubview(customView, filling: addCustomViewTo)
		}
	}
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
