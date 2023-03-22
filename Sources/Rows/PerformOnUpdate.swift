//
//  PerformOnUpdate.swift
//  Demo
//
//  Created by Andreas Verhoeven on 22/03/2023.
//

import Foundation

extension Row {
	public class PeformOnUpdate: SectionContent<ContainerType> {
		init(callback: () -> Void) {
			super.init(items: [])
			callback()
		}
	}
}
