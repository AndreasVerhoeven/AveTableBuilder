//
//  RowModifyable+Menu.swift
//  Demo
//
//  Created by Andreas Verhoeven on 06/03/2023.
//

import UIKit
import AutoLayoutConvenience

public enum MenuTitleStyle {
	case value1
	case subtitle
	case accessory
}

extension RowModifyable {
	
	/// Shows a menu when this row is tapped; the accessoryView will have a button with an up-down-chevron and the given title
	@discardableResult public func menu(title: String? = nil, titleStyle: MenuTitleStyle = .value1, _ menu: UIMenu?) -> Self {
		return self.menu(title: title, titleStyle: titleStyle, provider: { container in
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
		titleStyle: MenuTitleStyle = .value1,
		textProvider: @escaping (Collection.Element) -> String
	) -> Self where Collection.Element : Hashable {
		return menu(title: textProvider(binding.wrappedValue), titleStyle: titleStyle) { container in
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
		titleStyle: MenuTitleStyle = .value1,
		textProvider: @escaping (Collection.Element?) -> String
	) -> Self where Collection.Element : Equatable {
		return menu(title: textProvider(binding.wrappedValue), titleStyle: titleStyle) { container in
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
	
	/// Shows an optional menu when this row is selected. The accessoryView of the cell will have a button and the cell will be changed to style == `.value1` with a title to indicate the menu.
	@discardableResult public func menu(
		title: String? = nil,
		titleStyle: MenuTitleStyle = .value1,
		provider: @escaping (_ `self` : ContainerType) -> UIMenu?
	) -> Self {
		if titleStyle != .accessory {
			_ = modifyRows { item in
				item.cellStyle = titleStyle == .value1 ? .value1 : .subtitle
			}
		}
		
		var modifying: RowConfiguration = [.accessoryView]
		if titleStyle == .value1 {
			modifying.items.formUnion([.detailText])
		} else if titleStyle == .subtitle {
			modifying.items.formUnion([.detailText, .numberOfDetailLines, .detailTextColor])
		}
		
		_ = preConfigure(modifying: modifying) { container, cell, animated in
			let wrapperView = (cell.accessoryView as? MenuAccessoryButton.WrapperStackView) ?? MenuAccessoryButton.WrapperStackView()
			let button = wrapperView.menuButton
			button.isUserInteractionEnabled = false
			button.menuProvider = { [weak container] in
				guard let container else { return nil }
				return provider(container)
			}
			
			if let value = cell.value(forKeyPath: "style") as? Int,
			   let style = UITableViewCell.CellStyle(rawValue: value),
			   (style == .value1  || style == .subtitle) {
				button.customTitleLabel.isHidden = true
				if style == .subtitle {
					cell.detailTextLabel?.numberOfLines = 0
					cell.detailTextLabel?.setText(title, textColor: .secondaryLabel, animated: animated)
				} else {
					cell.detailTextLabel?.setText(title, animated: animated)
				}
			} else {
				button.customTitleLabel.contentMode = button.traitCollection.layoutDirection == .leftToRight ? .right : .left
				button.customTitleLabel.preferredMaxLayoutWidth = cell.frame.inset(by: cell.layoutMargins).width * 0.65
				button.setCustomTitle(title, animated: animated)
			}
			
			let newSize = button.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
			wrapperView.frame = CGRect(
				x: wrapperView.frame.maxX - newSize.width,
				y: wrapperView.frame.minY,
				width: newSize.width,
				height: newSize.height)
			cell.accessoryView = wrapperView
			cell.editingAccessoryView = wrapperView
		}
		
		_ = modifyRows { item in
			item.selectionHandlers.append { container, tableView, indexPath, rowInfo in
				guard let cell = tableView.cellForRow(at: indexPath) else { return }
				guard let menuButton = (cell.accessoryView as? MenuAccessoryButton.WrapperStackView)?.menuButton else { return }
				menuButton.showMenu()
			}
		}
		
		return self
	}
}

/// A button to show and launch a menu
class MenuAccessoryButton: UIButton {
	private let wrapperView = WrapperView()
	let customTitleLabel = UILabel(font: .ios.body, alignment: .right)
	let customImageView = UIImageView(image: UIImage(systemName: "chevron.up.chevron.down"), contentMode: .scaleAspectFit).prefersExactSize()
	
	class WrapperStackView: UIStackView {
		var menuButton = MenuAccessoryButton()
		
		override init(frame: CGRect) {
			super.init(frame: frame)
			addArrangedSubview(menuButton)
		}
		
		@available(*, unavailable)
		public required init(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	func setCustomTitle(_ title: String?, animated: Bool) {
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.hyphenationFactor = 0.5
		paragraphStyle.lineBreakMode = .byTruncatingTail
		let attributedTitle = NSAttributedString(string: title ?? "", attributes: [.paragraphStyle: paragraphStyle])
		customTitleLabel.setAttributedText(attributedTitle, animated: animated)
		customTitleLabel.isHidden = title?.isEmpty ?? true
	}
	
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
		
		customTitleLabel.numberOfLines = 2
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
