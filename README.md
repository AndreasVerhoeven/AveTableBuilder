# AveTableBuilder

This is a library that makes creating "static" table views much easier. With AveTableBuilder, you populate UITableViews in a declarative, SwiftUI-like way:

```
	Section("First Section") {
		Row(text: "First Row")
		Row.Switch(text: "Show the next row", binding: self.$showNextRow)
		
		if self.showNextRow {
			Row(text: "Next Row")
		}
	}
	
	Section("Second Section") {
		Row(text: "Another Row").textColor(.red)
	}
}
``` 

## Example:

This shows a demo of a simple "pizza order" table view. This is all there is to automatically populate and update the table view. No other code is necessary. 

![Demo Video](https://user-images.githubusercontent.com/168214/222715181-977e34c6-d81a-4881-b458-996fb53d65f3.gif)

```
class ViewController: UITableViewController {
	@TableState var includeDrinks = false
	@TableState var selectedToppings = Set<Topping>()
	@TableState var numberOfCocaColas = 0
	@TableState var numberOfBeers = 0
	
	lazy var builder = TableBuilder(controller: self) { `self` in
		Section.Stylished {
			Section {
				Row { `self`, cell, animated in
					cell.textLabel?.text = "Pizza Order"
					cell.textLabel?.font = .preferredFont(forTextStyle: .title3)
					cell.textLabel?.textAlignment = .center
				}
				
				Row(text: "Welcome to the pizza builder! Select what you want and we will make it happen")
					.numberOfLines(0)
					.textAlignment(.center)
					.textFont(.from(.ios.footnote))
				
				Row(text: "Visit our website").onSelect { `self` in
					UIApplication.shared.open(URL(string: "https://www.aveapps.com")!)
				}
				.textAlignment(.center)
				.textColor(.systemBlue)
				.backgroundColor(.secondarySystemBackground)
			}
			.backgroundColor(.systemRed)
			.textColor(.white)
			
			Section("Drinks") {
				Row.Switch(text: "Include Drinks", binding: self.$includeDrinks)
				
				if self.includeDrinks == true {
					Row.Stepper(text: "Coca-Cola", binding: self.$numberOfCocaColas)
					Row.Stepper(text: "Beer", binding: self.$numberOfBeers)
				}
			}
			
			Section.MultiSelection("Toppings", data: Topping.allCases, binding: self.$selectedToppings) { topping in
				Row(text: topping.rawValue.capitalized)
			}
			
			if self.selectedToppings.count > 0 || self.hadDrinks {
				Section {
					Row(text: "Order:", subtitle: self.orderSummary()).numberOfLines(0)
					
					Row.Action(text: "Complete Order") { `self` in
						self.completeOrder()
					}
				}
			}
		}
	}
}
```

## HowTo:

### TableBuilder

You create a `TableBuilder` that you give a `container`, `tableView` and an updater:

 - the container will be passed to every callback that is escaping, so that you don't create retain cycles by retain `self` in a closure
 - the table view will be taken over and configured by the builder
 - the updater needs to supply Sections and rows

```
   lazy var builder = TableBuilder(container: self, tableView: self.tableView) { `self` in
      // contents goes here
   }
   
   builder.update(animated: false) // start building
```

If you are in a `UITableViewController`, there's a convenience init to set the container and tableView at the same time:

```
	lazy var builder = TableBuilder(controller: self) { `self` in }
```  


### Sections

In the update callback, you define Sections:

```
   Section {}
   Section("OptionalHeader") {}
   Section("OptionalHeader", footer: "OptionalFooter") {}
   
   // section with a custom header
   Section {
   
   }.header(MyHeaderClass.self) { `self`, headerView, headerText, animated in
		headerView.label.setText(headerText, animated: animated)
   }
```

#### Section.Group

If you want to group multiple sections to apply a property to all its sections inside of it, you can wrap them in `Section.Group`:

```
    // all three sections will get the same custom header applied
	Section.Group {
	
		Section("First") {}
		Section("Second") {}
		Section("Third") {}
		
	}.header(MyHeaderClass.self) { `self`, headerView, headerText, animated in
		headerView.label.setText(headerText, animated: animated)
   }
```

#### Section.ForEach

If you want to iterate over a collection to create sections, use `Section.ForEach`:

```
    // this creates three sections, one for each element.
    // the elements need to be unique, since they are used to identify the section
    let items = ["A", "B", "C"]
	Section.ForEach(items) { element in
	    Section(item) {}
	}
	
	// if your elements are uniquely identified by a field, use the version which takes a specific `identifiedBy` field
	Section.ForEach(collection, identifiedBy: \.id) { element in
		Section(item) {}
	}
```


#### Section.MultiSelection

If you have a collection where each item can be picked using checkmarks, use a Section.MultiSelection. It'll automatically manages
the selection for you:

```
	let items = ["A", "B", "C"]
	@TableState selection = Set<String>()
	Section.MultiSelection(collection, binding: $selection) { element in
		Row(text: element)
	}
```


#### Section.Stylished 

This is a wrapper section that you can use to apply a stylished look: cells use a custom background color and headers use a bigger font:

```
	Section.Stylished {
		Section("First") {}
		Section("Second") {}
	}
```

### Rows:

Each section contains zero or more rows:

```
	Section {
		Row(text: "X")
	}
```

#### Row

A `Row` is the most basic of rows. There are several ways to create and configure rows:

##### Configure the row yourself

```
	Row { `self`, cell, animated in
		// this method is called every time this row needs to be configured. Apply your own configuration
		cell.textLabel?.setText("Some Text", animated: animated)
	}
	
	// rows with different `modifying` lists will never reuse the same cells,
	// once that do have the same lists will.
	Row(modifying: [.custom("MyConfiguration)]) { `self`, cell, animated in
		// configure here
	}
	
	Row(cellClass: MyCustomCell.self) { `self`, cell, animated in
	 // configure
	}
	
	Row(cellClass: MyCustomCell.self, style: .value1) { `self`, cell, animated in
	 // configure
	}
```

#### Use one of the convenience inits:

```
	// .default cells with a text and optional image
	Row(text: "Text")
	Row(text: "Text", image: someImage)
	Row(text: "Text", cellClass: MyCustomCell.self)
	Row(text: "Text", image: someImage, cellClass: MyCustomCell.self)
	
	// .value1 cells with a text, value text and optional image
	Row(text: "Text", value: "ValueText")
	Row(text: "Text", value: "ValueText", image: someImage)
	Row(text: "Text", value: "ValueText", cellClass: MyCustomCell.self)
	Row(text: "Text", value: "ValueText", image: someImage, cellClass: MyCustomCell.self)
	
	// subTitle cells with a text, subtitle and an optional image
	Row(text: "Text", subtitle: "Subtitle")
	Row(text: "Text", subtitle: "Subtitle", image: someImage)
	Row(text: "Text", subtitle: "Subtitle", cellClass: MyCustomCell.self)
	Row(text: "Text", subtitle: "Subtitle", image: someImage, cellClass: MyCustomCell.self)
```

#### Row.Switch

A row that has a switch as accessory

```
	@TableState var someVariable = true
	Row.Switch(text: "Text", binding: self.$someVariable) // someVariable and the switch reflect each other
	Row.Switch(text: "Text", image: someImage, binding: self.$someVariable)
	
	Row.Switch(text: "Text", isOn: someBoolean) { `self`, isOn in
		// do something with the new state here
	}
```


#### Row.Stepper

A row that shows a stepper with a label

```
	@TableState var value = 0
	
	Row.Stepper(text: "Text", binding self.$value) // value and the stepper reflect each other
	
```


#### Row.Action

A row that shows up as an actionable row, with tint colored label and centered text:

```
	Row.Action(text: "Perform my Action") { `self` in
		// do something
	}
```

### Row.Group

If you want to group multiple rows to apply a property to all its rows inside of it, you can wrap them in `Row.Group`:

```
    // all three rows will have a red background color
	Row.Group {
	
		Row("First") {}
		Row("Second") {}
		Row("Third") {}
		
	} 
```

#### Row.ForEach

If you want to iterate over a collection to create row, use `Row.ForEach`:

```
    // this creates three rows, one for each element.
    // the elements need to be unique, since they are used to identify the section
    let items = ["A", "B", "C"]
	Row.ForEach(items) { element in
	    Row(text: element)
	}
	
	// if your elements are uniquely identified by a field, use the version which takes a specific `identifiedBy` field
	Row.ForEach(collection, identifiedBy: \.id) { element in
		Row(text: element)
	}
```


#### Row.MultiSelection

If you have a collection where each item can be picked using checkmarks, use Row.MultiSelection. It'll automatically manages
the selection for you:

```
	let items = ["A", "B", "C"]
	@TableState selection = Set<String>()
	Row.MultiSelection(collection, binding: $selection) { element in
		Row(text: element)
	}
```


### Configuration

TableBuilder comes with a few convenience configuration modifiers that you can apply to rows, groups and sections:

 - if applied to a row, it will modify that row
 - if applied to a group, it will modify all rows in that group (section or row group)
 - if applied to a section, it will modify all rows in that section
 
 
 #### Order of application
 
 modifiers are "applied" inside out: the property or modifier that is configured deepest in the hierarchy "wins":
 
 ```
	Section {
		Row(text: "Row").backgroundColor(.red) // this row will be red
		Row(text: "Other") // this row will be green
		
		Row { `self`, cell, animated in
			// background color will be set to green here, but you can override it
		}
	}.backgroundColor(.green)
```

#### The modifiers:

##### .configure()
	Calls a configuration handler for a row that is added at the end of the configuration: it will be performed after every other configuration is done.

````
	// adds a configuration handler to a row
	.configure { `self`, cell, animated in /* configure cell here */ }
	
	// adds a configuration handler and tells what the handler is modifying for re-use purposes
	.configure(modifying: [.custom1]) { `self`, cell, animated in /* configure cell here */ }
	
	// adds a configuration handler that only works for cells of the given type
	.configure(cellOfType: MyCustomCell.self, modifying: []) { `self`, cell, animated in /* configure cell here */ }
````

##### .preConfigure()
	Calls a configuration handler for a row that is added at the front of the configuration: it will be performed before every other configuration is done.

````
	// adds a configuration handler to a row
	.preConfigure { `self`, cell, animated in /* configure cell here */ }
	
	// adds a configuration handler and tells what the handler is modifying for re-use purposes
	.preConfigure(modifying: [.custom1]) { `self`, cell, animated in /* configure cell here */ }
	
	// adds a configuration handler that only works for cells of the given type
	.preConfigure(cellOfType: MyCustomCell.self) { `self`, cell, animated in /* configure cell here */ }
````

##### Content

```
	.backgroundColor(.red) // sets a background color to the row
	.accessory(.disclosureIndicator) // sets an accessory to the row
	
	.textFont(preferredFont(forTextStyle: .title1)) // sets the textLabel's font
	.detailTextFont(preferredFont(forTextStyle: .title1)) // sets the detailTextLabel's font
	
	.textColor(.blue) // sets the textLabel's textColor
	.detailTextColor(.blue) // sets the detailTextLabel's textColor
	
	.textAlignment(.center) // sets the textLabel's alignment
	.detailTextAlignment(.center) // sets the detailTextLabel's alignment
	
	.numberOfLines(0) // sets the numberOfLines for both labels
	
	.imageTintColor(.green) // sets the imageView's tintColor
	
	.checked(true) // checkmarks the cell
	.checked(false) // removes the checkmark from the cell
 ```
 
 
 #### Handlers
 
 ```
	// called when the row is selected
	.onSelect { `self` in
	}
	
	// toggles a @TableState variable when the row is selected
	.onSelect(toggle: self.$someBooleanStateVariable)
	
	.leadingSwipeActions {  `self` in
		// return the leading swipe actions for this cell
	}
	
	.trailingSwipeActions {  `self` in
		// return the trailing swipe actions for this cell
	}
	
	.contextMenuProvider { `self`, point, cell in
		// return the context menu provider for this cell
	}
```


### Creating Custom Rows:

When creating custom rows you have two options: inherit from `Row` or from `SectionContent`.

- Inherit from `Row` when you model a single row (e.g. `Row.Switch`)
- Inherit from `SectionContent` when you model zero or more rows (e.g. `Row.Group`)

When inheriting from `SectionContent` you need to supply `RowInfo`s yourself.

### Creating Custom Sections:

When creating custom sections you have two options: inherit from `Section` or from `TableContent`.

- Inherit from `Section` when you model a single section
- Inherit from `TableContent` when you model zero or more rows (e.g. `Section.Group`)

When inheriting from `TableContent` you need to supply `SectionInfoWithRows`s yourself.

#### How does it work?

Every content modifier essentially adds another configuration handler to a row: new handlers are added at the front. When a cell is configured, all its configuration handlers are called in order, so outside modifiers are applied first, then inner ones.

## How does it work under the hood?

It uses Swift's ResultsBuilders. ResultsBuilder transform code into several different method calls into the ResultBuilder. Because of this, we know exactly where every row and section are in the code and so we can create automatic identifiers based on their position in the code. This, in turn, allows us to automatically create snapshots which are then diffed by `AveDataSource`.

In order to create actual cells, we need a mechanism to describe and configure cells: `RowInfo`. A RowInfo holds an id, a list of known modifications, a callback to create a cell, callbacks to configure a cell and callbacks for selection.

`RowInfo` are not created directly by the user, but they are wrapped into `SectionContent` subclasses: an object holder one-or-more `RowInfo`s. The most common `SectionContent` is a `Row`, which configures a single `RowInfo`. There's also `Row.ForEach` which iterates over a collection and creates `RowInfos` for each element.

Sections work the same way, apart that they also need to collect rows. Sections are described with a `SectionInfo`. Again, `SectionInfo`s are not created directly, but are wrapped into `TableContent` subclasses: `Section` is the most common one.

A `Section` is turned into a single `SectionInfoWithRows`.

Summarizing:
	- `TableContent` subclasses (e.g. `Section`) create `SectionInfoWithRows`s
	- `SectionInfoWithRows` is a `SectionInfo` and zero-or-more `RowInfo`
	- `SectionInfo` contains a unique identifier based on its position in code
	- `SectionInfo` contains information on how to configure a sections header and footer
	- `TableBuilder` uses the `SectionInfo` to configure the actual sections in the table view

And:
	- `SectionContent` subclasses (e.g. `Row`) create `RowInfo`s
	- `RowInfo` contains a unique identifier based on its position in code
	- `RowInfo` contains all information on how to create a cell for a row
	- `RowInfo` contains configuration callbacks and other handlers
	- `TableBuilder` uses `RowInfo`s to configure the actual rows & cells in the table view
	
### Known Modifications

UITableView tries to reuse cells based on a unique `Reuse Identifier`: cells with the same Reuse Identifier are considered to be of the same category. TableBuilder doesn't really bother you with creation of cells, just configuration, so how does it know which cells to reuse?

It does this by keeping track of the cell classes and styles and which properties are configured using the helper methods to create a unique ReuseIdentifier for all cells configuring themselves in the same way. If you call `backgroundColor()` on a Row, we want to make sure that each other Row that potentially reuses a cell also configures its backgroundColor, otherwise it might have a left over background color from another row. 

Whenever you call `backgroundColor`, we add a `.backgroundColor` to the `knownModifications` of the `RowInfo`: we do this for every property: `textColor()` adds a `.textColor` to the `knownModifications` etc: based on this we create a ReuseIdenitifier, so only rows that modify the same information get reused.

If the user configures their own cells, we add a `.manual` `knownModification`, but it's then up to the user to always configure the cell correctly. Users can introduce their own `knownModification`s to group cells into groups by setting the `modifying:` property:

```
    // these two rows will have the same ReuseIdentifier and thus 
    // will reuse each others cells
	Row(modifying: .custom("MyCategory")) { `self`, cell, animated in
	   // configure cell here
	}
	
	
	Row(modifying: .custom("MyCategory")) { `self`, cell, animated in
	   // configure cell here
	}
	
	// this cell will never reuse cells from the previous two rows
	Row { `self`, cell, animated in
	   // configure cell here
	}
``` 
	

### Why classes and not structs?

Good question. The first iteration of this library used structs and generic protocols; Unfortunately, I ran into a dozen or so different Swift compiler crashes: generics & result builders are super buggy still in Swift.
 
