//
//  StylishedSection.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit
import AutoLayoutConvenience
import UIKitAnimations

extension Section {
	open class Stylished: TableContent<ContainerType> {
		public init(@TableContentBuilder<ContainerType> builder: () -> TableContentBuilder<ContainerType>.Collection) {
			let section = Section.Group(builder: builder).stylished()
			super.init(items: section.items)
		}
	}
}

public protocol ButtonHaveableHeader {
	func setButton(title: String?, animated: Bool, callback: (() -> Void)?)
}

open class StylishedCustomHeader: UITableViewHeaderFooterView {
	public let label = UILabel(font: .ios.headline.rounded)
	public let button = UIButton(font: .ios.headline.rounded, type: .system)
	
	public var buttonCallback: (() -> Void)?
	
	@objc private func buttonTapped(_ sender: Any) {
		buttonCallback?()
	}
	
	private func updateAlignment() {
		if traitCollection.preferredContentSizeCategory.isAccessibilityCategory == true {
			button.contentHorizontalAlignment = .leading
		} else {
			button.contentHorizontalAlignment = .trailing
		}
	}
	
	open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		updateAlignment()
	}
	
	public override init(reuseIdentifier: String?) {
		super.init(reuseIdentifier: reuseIdentifier)
		button.isHidden = true
		button.contentHorizontalAlignment = .trailing
		button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
		
		contentView.addSubview(
			.autoAdjustingHorizontallyStacked(
				label.disallowHorizontalGrowing(),
				button.prefersExactSize(),
				alignment: .lastBaseline,
				spacing: UIStackView.spacingUseDefault
			),
			filling: .bottom(.superview, others: .layoutMargins),
			insets: .bottom(6)
		)
		
		updateAlignment()
	}
	
	@available(*, unavailable)
	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

extension StylishedCustomHeader: ButtonHaveableHeader {
	public func setButton(title: String?, animated: Bool, callback: (() -> Void)? = nil) {
		buttonCallback = callback
		button.isHidden = (title == nil)
		if let title {
			button.titleLabel?.setText(title, animated: animated)
			button.setTitle(title, for: .normal)
		}
	}
}


extension TableContent {
	public func stylished() -> Self {
		_ = self.stylishedHeader().backgroundColor(.secondarySystemBackground)
		
		items = items.map { item in
			var newItem = item
			newItem.sectionInfo.firstAddedCallbacks.append({ container, tableView in
				tableView.backgroundColor = .systemBackground
			})
			return newItem
		}
		return self
	}
	
	public func stylishedHeader() -> Self {
		return header(StylishedCustomHeader.self) { container, view, text, animated in
			view.button.isHidden = true
			view.label.setText(text, animated: animated)
		}
	}
}
