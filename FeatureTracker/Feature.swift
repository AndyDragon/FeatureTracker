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

class CodableFeature: Codable {
    var date: Date = Date.now
    var raw: Bool = false
    var notes: String = ""
    
    init(_ feature: Feature) {
        self.date = feature.date
        self.raw = feature.raw
        self.notes = feature.notes
    }
    
    func toFeature() -> Feature {
        return Feature(date: date, raw: raw, notes: notes)
    }
    
    enum CodingKeys: CodingKey {
        case date
        case dateV2
        case raw
        case notes
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateV2 = try container.decodeIfPresent(Date.self, forKey: .dateV2)
        if dateV2 != nil {
            date = dateV2!
        } else {
            let oldDate = try container.decode(Double.self, forKey: .date)
            date = Date(timeIntervalSinceReferenceDate: oldDate)
        }
        raw = try container.decode(Bool.self, forKey: .raw)
        notes = try container.decode(String.self, forKey: .notes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .dateV2)
        try container.encode(raw, forKey: .raw)
        try container.encode(notes, forKey: .notes)
    }
}
