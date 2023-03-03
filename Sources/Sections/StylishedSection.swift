//
//  StylishedSection.swift
//  TableBuilder
//
//  Created by Andreas Verhoeven on 01/03/2023.
//

import UIKit
import AutoLayoutConvenience

extension Section {
	class Stylished: TableContent<ContainerType> {
		init(@TableContentBuilder<ContainerType> builder: () -> TableContentBuilder<ContainerType>.Collection) {
			let section = Section.Group(builder: builder).stylished()
			super.init(items: section.items)
		}
	}
}

class StylishedCustomHeader: UITableViewHeaderFooterView {
	let label = UILabel(font: .ios.headline.rounded)
	let button = UIButton(font: .ios.headline.rounded, type: .system)
	
	var buttonCallback: (() -> Void)?
	
	@objc private func buttonTapped(_ sender: Any) {
		buttonCallback?()
	}
	
	override init(reuseIdentifier: String?) {
		super.init(reuseIdentifier: reuseIdentifier)
		button.isHidden = true
		button.contentHorizontalAlignment = .trailing
		button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
		
		contentView.addSubview(
			.horizontallyStacked(
				label.disallowHorizontalGrowing(),
				button.disallowHorizontalShrinking(),
				alignment: .lastBaseline,
				spacing: UIStackView.spacingUseDefault
			),
			filling: .bottom(.superview, others: .layoutMargins),
			insets: .bottom(6)
		)
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}


extension TableContent {
	
	func stylished() -> Self {
		return self.stylishedHeader().backgroundColor(.secondarySystemBackground)
	}
	
	func stylishedHeader() -> Self {
		return header(StylishedCustomHeader.self) { container, view, text, animated in
			view.label.setText(text, animated: animated)
		}
	}
}
