//
//  CustomViewRow.swift
//  Demo
//
//  Created by Andreas Verhoeven on 07/03/2023.
//

import UIKit

extension Row {
	open class CustomView: Static {
		public init<View: UIView>(
			viewClass: View.Type = UIView.self,
			creation: ((_ `self`: ContainerType) -> View)? = nil,
			configure: @escaping (_ `self`: ContainerType, _ view: View, _ animated: Bool) -> Void
		) {
			super.init(cellClass: CustomViewCell.self, initial: { container, cell in
				let view = creation?(container) ?? View.init(frame: .zero)
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
	}
	
}

fileprivate class CustomViewCell: UITableViewCell {
	var customView: UIView? {
		didSet {
			guard customView !== oldValue else { return }
			customView?.removeFromSuperview()
			guard let customView else { return }
			contentView.addSubview(customView, filling: .superview)
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
