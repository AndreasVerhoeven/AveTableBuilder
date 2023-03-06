//
//  TableBuilderController.swift
//  Demo
//
//  Created by Andreas Verhoeven on 03/03/2023.
//

import UIKit

// A controller that shows a table view with the contents of a passed in builder.
public class TableBuilderController<T: AnyObject>: UITableViewController {
	let contents: (T) -> TableContentBuilder<T>.Collection
	let container: T
	
	public init(
		style: UITableView.Style = .insetGrouped,
		 title: String? = nil,
		 container: T,
		 @TableContentBuilder<T> contents: @escaping (T) -> TableContentBuilder<T>.Collection
	) {
		self.contents = contents
		self.container = container
		super.init(style: style)
		self.title = title
	}
	
	@available(*, unavailable)
	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	// MARK: - Private
	private(set) public  lazy var builder = TableBuilder(tableView: tableView, container: container) { [weak self] container in
		if let self {
			self.contents(container)
		}
	}
	
	// MARK: - UIViewController
	public override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = title
		builder.update(animated: false)
	}
}
