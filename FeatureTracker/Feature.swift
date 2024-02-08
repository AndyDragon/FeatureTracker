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
    var date: Date
    var raw: Bool
    var notes: String

    init(date: Date = .now, raw: Bool = false, notes: String = "") {
        self.date = date
        self.raw = raw
        self.notes = notes
    }
}
