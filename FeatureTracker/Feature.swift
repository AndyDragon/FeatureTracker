//
//  Feature.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import Foundation
import SwiftData

@Model
class Feature : Codable, Comparable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date.now
    var raw: Bool = false
    var notes: String = ""
    var page: Page?
    
    init(date: Date = .now, raw: Bool = false, notes: String = "") {
        self.date = date
        self.raw = raw
        self.notes = notes
    }
    
    init(id: UUID, date: Date, raw: Bool, notes: String) {
        self.id = id
        self.date = date
        self.raw = raw
        self.notes = notes
    }
    
    static func == (lhs: Feature, rhs: Feature) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func < (lhs: Feature, rhs: Feature) -> Bool {
        return lhs.date < rhs.date
    }
    
    enum CodingKeys: CodingKey {
        case id
        case date
        case raw
        case notes
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        raw = try container.decode(Bool.self, forKey: .raw)
        notes = try container.decode(String.self, forKey: .notes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(raw, forKey: .raw)
        try container.encode(notes, forKey: .notes)
    }
}
