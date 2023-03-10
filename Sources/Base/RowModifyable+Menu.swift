//
//  RowModifyable+Menu.swift
//  Demo
//
//  Created by Andreas Verhoeven on 06/03/2023.
//

import UIKit
import AutoLayoutConvenience

extension RowModifyable {
	/// Shows a menu when this row is tapped; the accessoryView will have a button with an up-down-chevron and the given title
	@discardableResult public func menu(title: String? = nil, _ menu: UIMenu?) -> Self {
		return self.menu(title: title, provider: { container in
			return menu
		})
	}
	
	/// Shows a single selected option (via a binding) and allows the user to change the selection via an inline menu.
	/// The elements in `customOptions` are shown in a different part of the popup menu.
	/// You need to provide a textProvider that turns items into displayable strings.
	@discardableResult public func inlineOptions<Collection: RandomAccessCollection>(
		_ data: Collection,
		binding: TableBinding<Collection.Element>,
		showSeparately customOptions: Set<Collection.Element> = [],
		textProvider: @escaping (Collection.Element) -> String
	) -> Self where Collection.Element : Hashable {
		return menu(title: textProvider(binding.wrappedValue)) { container in
			var mainActions = [UIAction]()
			var customActions = [UIAction]()
			
			for element in data {
				let action = UIAction(title: textProvider(element), state: binding.wrappedValue == element ? .on : .off, handler: { _ in
					binding.wrappedValue = element
				})
				if customOptions.contains(element) {
					customActions.append(action)
				} else {
					mainActions.append(action)
				}
			}
			
			let mainMenu = UIMenu(title: "", options: .displayInline, children: mainActions)
			let customMenu = UIMenu(title: "", options: .displayInline, children: customActions)
			return UIMenu(title: "", children: [mainMenu, customMenu])
		}
	}
	
	/// Shows a single optional selected option (via a binding) and allows the user to change the selection via an inline menu.
	/// The `nil` option is shown as a custom option in the menu.
	/// You need to provide a textProvider that turns items into displayable strings.
	@discardableResult public func inlineOptions<Collection: RandomAccessCollection>(
		_ data: Collection,
		binding: TableBinding<Collection.Element?>,
		textProvider: @escaping (Collection.Element?) -> String
	) -> Self where Collection.Element : Equatable {
		return menu(title: textProvider(binding.wrappedValue)) { container in
			let items = data.map { item in
				return UIAction(title: textProvider(item),
								state: binding.wrappedValue == item ? .on : .off, handler: { _ in
					binding.wrappedValue = item
				}) }
			let itemsMenu = UIMenu(title: "", options: .displayInline, children: items)
			
			let noneItem = UIAction(title: textProvider(nil), state: binding.wrappedValue == nil ? .on: .off, handler: { _ in
				binding.wrappedValue = nil
			})
			let noneMenu = UIMenu(title: "", options: .displayInline, children: [noneItem])
			return UIMenu(title: "", children: [noneMenu, itemsMenu])
		}
	}
	
	/// Shows an optional menu when this row is selected. The accessoryView of the cell will have a button with a title to indicate the menu.
	@discardableResult public func menu(title: String? = nil, provider: @escaping (_ `self` : ContainerType) -> UIMenu?) -> Self {
		_ = preConfigure(modifying: [.accessoryView]) { container, cell, animated in
			let button = (cell.accessoryView as? MenuAccessoryButton) ?? MenuAccessoryButton()
			button.isUserInteractionEnabled = false
			button.menuProvider = { [weak container] in
				guard let container else { return nil }
				return provider(container)
			}
			button.customTitleLabel.contentMode = .right
			button.customTitleLabel.setText(title, animated: false)
			button.customTitleLabel.isHidden = title?.isEmpty ?? true
			button.customTitleLabel.preferredMaxLayoutWidth = cell.layoutMarginsGuide.layoutFrame.width * 0.75
			let newSize = button.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
			button.frame = CGRect(
				x: button.frame.maxX - newSize.width,
				y: button.frame.minY,
				width: newSize.width,
				height: newSize.height)
			cell.accessoryView = button
			cell.editingAccessoryView = button
		}
		_ = onSelect { `container` in
			guard let cell = SectionContent<ContainerType>.currentCell else { return }
			guard let menuButton = cell.accessoryView as? MenuAccessoryButton else { return }
			menuButton.showMenu()
		}
		
		return self
	}
}

/// A button to show and launch a menu
fileprivate class MenuAccessoryButton: UIButton {
	private let wrapperView = WrapperView()
	let customTitleLabel = UILabel(font: .ios.body, alignment: .right)
	let customImageView = UIImageView(image: UIImage(systemName: "chevron.up.chevron.down"), contentMode: .scaleAspectFit).prefersExactSize()
	
	var customMenu: UIMenu? {
		didSet {
			if #available(iOS 14, *) {
				self.menu = customMenu
			} else {
				self.wrapperView.menu = customMenu
			}
		}
	}
	
	typealias MenuProvider = () -> UIMenu?
	var menuProvider: MenuProvider?
	
	func showMenu() {
		if let menuProvider {
			customMenu = menuProvider()
		}
		
		let interaction: UIContextMenuInteraction?
		if #available(iOS 14, *) {
			interaction = contextMenuInteraction
		} else {
			interaction = wrapperView.interactions.compactMap { $0 as? UIContextMenuInteraction }.first
		}
		
		let parts = ["present", "Menu", "At", "Location"]
		let selector = NSSelectorFromString("_" + parts.joined() + ":")
		if let interaction, interaction.responds(to: selector) {
			interaction.perform(selector, with: center)
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		customTitleLabel.lineBreakMode = .byTruncatingTail
		customTitleLabel.textColor = .secondaryLabel
		customImageView.tintColor = .tertiaryLabel
		customImageView.tintAdjustmentMode = .normal
		addSubview(wrapperView, filling: .superview)
		addSubview(.horizontallyStacked(customTitleLabel, customImageView, alignment: .center, spacing: 4), filling: .superview)
		
		if #available(iOS 14, *) {
		} else {
			wrapperView.addInteraction(UIContextMenuInteraction(delegate: wrapperView))
		}
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

extension MenuAccessoryButton {
	fileprivate class WrapperView: UIView, UIContextMenuInteractionDelegate {
		var menu: UIMenu?
		
		func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
			return UIContextMenuConfiguration(identifier: nil, previewProvider: {
				let controller = UIViewController()
				controller.preferredContentSize = CGSize(width: self.bounds.width, height: self.bounds.height - 20)
				return controller
			}, actionProvider: { _ in
				return self.menu
			})
		}
		
		func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
			animator?.addAnimations {
				// iOS 13: hide blur + preview
				guard let container = self.window?.subviews.last else { return }
				if let view = container.subviews.compactMap({ $0 as? UIVisualEffectView }).first {
					view.isHidden = true
				}
				if container.subviews.count > 1 {
					container.subviews[1].subviews.first?.isHidden = true
				}
			}
		}
	}
}
