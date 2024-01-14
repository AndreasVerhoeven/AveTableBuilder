//
//  EmptyHeaderFooter.swift
//  Demo
//
//  Created by Andreas Verhoeven on 14/01/2024.
//

import UIKit

extension TableContent {
	/// Sets an empty header to this section with a specified height. Defaults to the hairline height.
	public func fixedEmptyHeader(height: CGFloat = 1.0 / UIScreen.main.scale) -> Self {
		return header(EmptyFooterHeaderView.self) { container, view, text, animated in
			view.fixedHeight = height
		}
	}
	
	/// Sets an empty footer to this section with a specified height. Defaults to the hairline height.
	public func fixedEmptyFooter(height: CGFloat = 1.0 / UIScreen.main.scale) -> Self {
		return footer(EmptyFooterHeaderView.self) { container, view, text, animated in
			view.fixedHeight = height
		}
	}
}

open class EmptyFooterHeaderView: UITableViewHeaderFooterView {
	private var heighConstraint: NSLayoutConstraint?
	
	open var fixedHeight: CGFloat = .greatestFiniteMagnitude {
		didSet {
			guard fixedHeight != oldValue else { return }
			if let heighConstraint {
				heighConstraint.constant = fixedHeight
			} else {
				let newHeightConstraint = heightAnchor.constraint(equalToConstant: fixedHeight)
				heighConstraint = newHeightConstraint
				NSLayoutConstraint.activate([newHeightConstraint])
			}
		}
	}
}
