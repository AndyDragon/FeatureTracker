//
//  Feature.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import Foundation
import SwiftData

@Model
class Feature {
    var date: Date = Date.now
    var raw: Bool = false
    var notes: String = ""
    var page: Page?

    init(date: Date = .now, raw: Bool = false, notes: String = "") {
        self.date = date
        self.raw = raw
        self.notes = notes
    }
}
