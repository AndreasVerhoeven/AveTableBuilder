//
//  ViewController.swift
//  Demo
//
//  Created by Andreas Verhoeven on 16/05/2021.
//

import UIKit

enum Topping: String, CaseIterable {
	case olives
	case cheese
	case eggplant
	case mushrooms
	case chilis
}

enum Extra: String, CaseIterable {
	case mozarellaSticks
	case chiliCheeseNuggets
	case garlicBread
}

class ViewController: UITableViewController {
	// this is the state that we keep which makes the TableBuilder update itself when changed.
	@TableState var includeDrinks = false
	@TableState var selectedToppings = Set<Topping>()
	@TableState var numberOfCocaColas = 0
	@TableState var numberOfBeers = 0
	@TableState var extra: Extra?
	
	@TableState var start: Date?
	
	// This is our builder that turns out table description into actual cells
	lazy var builder = TableBuilder(controller: self) { `self` in
		// this is a special wrapper that makes everything in it use a different cell background color and use custom headers
		Section.Stylished {
			// Our first section: no title and two rows
			if self.selectedToppings.count == 0 && !self.hasDrinks {
				Section {
					// this is a row that is manually configurred
					Row { `self`, cell, animated in
						cell.textLabel?.text = "Pizza Order"
						cell.textLabel?.font = .preferredFont(forTextStyle: .title3)
						cell.textLabel?.textAlignment = .center
					}
					
					// this is a row that uses the build in configuration helpers
					Row(text: "Welcome to the pizza builder! Select what you want and we will make it happen")
						.numberOfLines(0)
						.textAlignment(.center)
						.textFont(.from(.ios.footnote))
					
					// This is a row that has an `onSelect` handler: when cells have an onSelect handler,
					// their `selectionStyle` will be set to default.
					// Note that `self` is passed in as an argument, so that we do not create retain cycles.
					Row(text: "Visit our website").onSelect { `self` in
						UIApplication.shared.open(URL(string: "https://www.aveapps.com")!)
					}.textAlignment(.center).textColor(.systemBlue).backgroundColor(.secondarySystemBackground)
				}
				.backgroundColor(.systemRed) // we can also apply a background color to all cells at once
				.textColor(.white) // also text colors!
								   // Note that properties are applied outside-in: properties deeper will override properties
								   // on the outside
			}
			
			// Just a section with a header
			Section("Drinks") {
				// this is a switch row that is bound to the includeDrinks `TableState` variable:
				// the switch will reflect the value of the variable and the variable will automatically
				// be updated.
				Row.Switch(text: "Include Drinks", binding: self.$includeDrinks)
				
				// These are two rows that are shown conditionally: If the includeDrinks variable
				// is updated, we show these rows, otherwise not.
				if self.includeDrinks == true {
					// A stepper row shows a stepper with a value. We also use a binding to a `TableState`
					// here to keep the row and the variable in sync.
					Row.Stepper(text: "Coca-Cola", binding: self.$numberOfCocaColas)
					Row.Stepper(text: "Beer", binding: self.$numberOfBeers)
				}
			}
			
			Section("Extra's") {
				Row(text: "Snack").inlineOptions(Extra.allCases, binding: self.$extra) { $0?.rawValue ?? "None" }
			}
			
			// this is a special kind of setting that shows all items in a Collection and then makes sure
			// that it reflects the selection state of the `selectedToppings` `TableState` variable:
			// when you select something, the variable is updated and vice-versa.
			Section.MultiSelection("Toppings", data: Topping.allCases, binding: self.$selectedToppings) { topping in
				Row(text: topping.rawValue.capitalized)
			}.selectionButtonTitles(selectAll: "Select All Items", deselectAll: "Deselect All Items")
			
			if self.selectedToppings.count > 0 || self.hasDrinks {
				Section {
					Row(text: "Order:", subtitle: self.orderSummary()).numberOfLines(0).noAnimatedContentChanges()
					
					// an action show renders as a "button". The callback is triggered when the user selects the row.
					// Note that `self` is passed in as a parameter, as to not create retain cycles.
					Row.Action(text: "Complete Order") { `self` in
						self.completeOrder()
					}.textFont(.from(.ios.headline.medium)).numberOfLines(0)
				}
			}
		}
	}
	
	private var hasDrinks: Bool {
		return includeDrinks && (numberOfCocaColas > 0 || numberOfBeers > 0)
	}
	
	private func orderSummary() -> String {
		var items = [String]()
		if selectedToppings.isEmpty == false {
			items += selectedToppings.map(\.rawValue.capitalized).sorted()
		}
		
		if includeDrinks {
			if numberOfCocaColas > 0 {
				items += ["Coca Cola \(numberOfCocaColas)x"]
			}
			
			if numberOfBeers > 0 {
				items += ["Beers: \(numberOfBeers)x"]
			}
		}
		
		if let snack = extra {
			items += ["Free Snack: \(snack.rawValue)"]
		}
		
		return items.map{ "- \($0)" }.joined(separator: "\n")
	}
	
	private func completeOrder() {
		let alert = UIAlertController(title: "Complete Order", message: "Done!", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel))
		present(alert, animated: true)
	}
	
	// MARK: - UIViewController
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// monitor changes to our state
		_includeDrinks.onChange { newValue in
			print("IncludeDrinks changed to: \(newValue)")
		}
		
		builder.update(animated: false) // fire up the builder
	}
}

