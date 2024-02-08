//
//  Page.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import Foundation
import SwiftData

@Model
class Page {
    var name: String
    var notes: String
    var count: Int
    @Relationship(deleteRule: .cascade) var features = [Feature]()

    init(name: String = "", notes: String = "", count: Int = 1) {
        self.name = name
        self.notes = notes
        self.count = count
    }
}
