//
//  RowModifyable+Menu.swift
//  Demo
//
//  Created by Andreas Verhoeven on 06/03/2023.
//

import UIKit
import AutoLayoutConvenience

/// Determines how menus show their title  in their row when not opened
public enum MenuTitleStyle {
	/// the menu title is shown as a `value1` title on the trailing side. Default option.
	case value1
	/// the menu  title is shown as a `subtitle` below the text
	case subtitle
	/// the menu title  is part of the `accessory`
	case accessory
	/// the menu title is shown as the main text
	case text
	
	/// this is the default way to show a menu title
	public static var `default`: Self { .value1 }
}

extension RowModifyable {
	/// Shows a menu when this row is tapped; the accessoryView will have a button with an up-down-chevron and the given title
	@discardableResult public func menu(title: String? = nil, titleStyle: MenuTitleStyle = .default, _ menu: UIMenu?) -> Self {
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
		titleStyle: MenuTitleStyle = .default,
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
	@discardableResult public func inlineOptions<Collection: Sequence>(
		_ data: Collection,
		binding: TableBinding<Collection.Element?>,
		allowsSelectingNone: Bool = true,
		titleStyle: MenuTitleStyle = .default,
		textProvider: @escaping (Collection.Element?) -> String
	) -> Self where Collection.Element : Equatable {
		return inlineOptions(data, binding: binding, identifiedBy: { $0 }, allowsSelectingNone: allowsSelectingNone, titleStyle: titleStyle, textProvider: textProvider)
	}
	
	/// Shows a single optional selected option (via a binding) and allows the user to change the selection via an inline menu.
	/// The `nil` option is shown as a custom option in the menu.
	/// You need to provide a textProvider that turns items into displayable strings.
	@discardableResult public func inlineOptions<Collection: Sequence>(
		_ data: Collection,
		binding: TableBinding<Collection.Element.ID?>,
		allowsSelectingNone: Bool = true,
		titleStyle: MenuTitleStyle = .default,
		textProvider: @escaping (Collection.Element?) -> String
	) -> Self where Collection.Element : Identifiable {
		let newBinding = TableBinding<Collection.Element?>(get: {
			data.first { $0.id == binding.wrappedValue }
		}, set: {
			binding.wrappedValue = $0?.id
		})
		return inlineOptions(data, binding: newBinding, identifiedBy: { $0.id }, allowsSelectingNone: allowsSelectingNone, titleStyle: titleStyle, textProvider: textProvider)
	}
	
	/// Shows a single optional selected option (via a binding) and allows the user to change the selection via an inline menu.
	/// The `nil` option is shown as a custom option in the menu.
	/// You need to provide a textProvider that turns items into displayable strings.
	@discardableResult public func inlineOptions<Collection: Sequence>(
		_ data: Collection,
		binding: TableBinding<Collection.Element?>,
		allowsSelectingNone: Bool = true,
		titleStyle: MenuTitleStyle = .default,
		textProvider: @escaping (Collection.Element?) -> String
	) -> Self where Collection.Element : Identifiable {
		return inlineOptions(data, binding: binding, identifiedBy: { $0.id }, allowsSelectingNone: allowsSelectingNone, titleStyle: titleStyle, textProvider: textProvider)
	}
	
	/// Shows a single optional selected option (via a binding) and allows the user to change the selection via an inline menu.
	/// The `nil` option is shown as a custom option in the menu.
	/// You need to provide a textProvider that turns items into displayable strings.
	@discardableResult public func inlineOptions<Collection: Sequence, ID: Equatable>(
		_ data: Collection,
		binding: TableBinding<Collection.Element?>,
		identifiedBy: @escaping (Collection.Element) -> ID,
		allowsSelectingNone: Bool = true,
		titleStyle: MenuTitleStyle = .default,
		textProvider: @escaping (Collection.Element?) -> String
	) -> Self {
		return self
	}
	
	/// Shows an optional menu when this row is selected. The accessoryView of the cell will have a button and the cell will be changed to style == `.value1` with a title to indicate the menu.
	@discardableResult public func menu(
		title: String? = nil,
		titleStyle: MenuTitleStyle = .default,
		provider: @escaping (_ `self` : ContainerType) -> UIMenu?
	) -> Self {
		if titleStyle != .accessory && titleStyle != .text {
			_ = modifyRows { item in
				item.cellStyle = titleStyle == .value1 ? .value1 : .subtitle
			}
		}
		
		var modifying: RowConfiguration = [.accessoryView]
		if titleStyle == .value1 {
			modifying.items.formUnion([.detailText])
		} else if titleStyle == .subtitle {
			modifying.items.formUnion([.detailText, .numberOfDetailLines, .detailTextColor])
		} else if titleStyle == .text {
			modifying.items.formUnion([.detailText])
		}
		
		_ = preConfigure(modifying: modifying) { container, cell, animated in
			let wrapperView = (cell.accessoryView as? MenuAccessoryButton.WrapperStackView) ?? MenuAccessoryButton.WrapperStackView()
			let button = wrapperView.menuButton
			button.isUserInteractionEnabled = false
			button.showFromCell = (titleStyle == .text)
			button.showFromCell = (titleStyle == .text)
			button.menuProvider = { [weak container] in
				guard let container else { return nil }
				return provider(container)
			}
			
			if titleStyle == .text {
				cell.textLabel?.setText(title, animated: animated)
			} else if let value = cell.value(forKeyPath: "style") as? Int,
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

extension RowCells {
	public class OptionPickerCell: UITableViewCell {
		public let menuButton = MenuAccessoryButton()
		
		public typealias MenuProvider = () -> UIMenu?
		public var menu: UIMenu? {
			get { menuButton.customMenu }
			set { menuButton.customMenu = newValue }
		}
		public var menuProvider: MenuProvider? {
			get { menuButton.menuProvider }
			set { menuButton.menuProvider = newValue }
		}
		
		public func showMenu() {
			menuButton.showMenu()
		}
		
		public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
			guard let point = touches.first?.location(in: self), hitTest(point, with: event) != nil else { return }
			showMenu()
		}

		public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
			super.init(style: style, reuseIdentifier: reuseIdentifier)
			accessoryView = menuButton
			editingAccessoryView = menuButton
		}
		
		@available(*, unavailable)
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
}

/// A button to show and launch a menu
public class MenuAccessoryButton: UIButton {
	private let wrapperView = WrapperView()
	let customTitleLabel = UILabel(font: .ios.body, alignment: .right)
	let customImageView = UIImageView(image: UIImage(systemName: "chevron.up.chevron.down"), contentMode: .scaleAspectFit).prefersExactSize()
	let customView = UIView()
	
	var showFromCell = false
	
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
	
	public func setCustomTitle(_ title: String?, animated: Bool) {
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.hyphenationFactor = 0.5
		paragraphStyle.lineBreakMode = .byTruncatingTail
		let attributedTitle = NSAttributedString(string: title ?? "", attributes: [.paragraphStyle: paragraphStyle])
		customTitleLabel.setAttributedText(attributedTitle, animated: animated)
		customTitleLabel.isHidden = title?.isEmpty ?? true
	}
	
	public var customMenu: UIMenu? {
		didSet {
			if #available(iOS 14, *) {
				self.menu = customMenu
			} else {
				self.wrapperView.menu = customMenu
			}
		}
	}
	
	public typealias MenuProvider = () -> UIMenu?
	public var menuProvider: MenuProvider?
	
	public func showMenu() {
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
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		customView.isUserInteractionEnabled = false
		addSubview(customView)
		
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
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		if showFromCell == true, let view = superview?.superview {
			customView.frame = view.convert(view.bounds, to: self)
			customView.frame.size.width = 80
		} else {
			customView.frame = .zero
		}
	}
	
	
	@available(iOS 14, *)
	public override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		if showFromCell == true {
			return UITargetedPreview(view: customView)
		} else {
			return super.contextMenuInteraction(interaction, previewForHighlightingMenuWithConfiguration: configuration)
		}
	}
	
	@available(iOS 14, *)
	public override func menuAttachmentPoint(for configuration: UIContextMenuConfiguration) -> CGPoint {
		guard showFromCell == true, let view = superview?.superview else { return super.menuAttachmentPoint(for: configuration) }
		
		let point = view.convert(CGPoint(x: view.bounds.minX + 8, y: view.bounds.maxY - 8), to: self)
		return point
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
			animator?.addCompletion {guard let container = self.window?.subviews.last else { return }
				if container.subviews.count > 1 {
					UIView.animate(withDuration: 0.25) {
						container.subviews[1].subviews.last?.layer.shadowColor = UIColor.black.cgColor
						container.subviews[1].subviews.last?.layer.shadowRadius = 25
						container.subviews[1].subviews.last?.layer.shadowOffset = .zero
						container.subviews[1].subviews.last?.layer.shadowOpacity = 0.15
					}
				}
			}
		}
	}
}
