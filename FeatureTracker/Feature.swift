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
    var id: UUID = UUID()
    var date: Date = Date.now
    var raw: Bool = false
    var notes: String = ""
    var page: Page?
    
    init(id: UUID = UUID(), date: Date = .now, raw: Bool = false, notes: String = "") {
        self.id = id
        self.date = date
        self.raw = raw
        self.notes = notes
    }
}

class CodableFeature: Codable {
    var id: UUID = UUID()
    var date: Date = Date.now
    var raw: Bool = false
    var notes: String = ""
    
    init(_ feature: Feature) {
        self.id = feature.id
        self.date = feature.date
        self.raw = feature.raw
        self.notes = feature.notes
    }
    
    func toFeature() -> Feature {
        return Feature(id: id, date: date, raw: raw, notes: notes)
    }
    
    enum CodingKeys: CodingKey {
        case id
        case date
        case dateV2
        case raw
        case notes
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
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
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .dateV2)
        try container.encode(raw, forKey: .raw)
        try container.encode(notes, forKey: .notes)
    }
}
