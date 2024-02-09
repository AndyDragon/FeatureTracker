//
//  Feature.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import Foundation
import SwiftData

@Model
class Feature : Codable{
    var date: Date = Date.now
    var raw: Bool = false
    var notes: String = ""
    var page: Page?
    
    init(date: Date = .now, raw: Bool = false, notes: String = "") {
        self.date = date
        self.raw = raw
        self.notes = notes
    }
    
    enum CodingKeys: CodingKey {
        case date
        case raw
        case notes
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        raw = try container.decode(Bool.self, forKey: .raw)
        notes = try container.decode(String.self, forKey: .notes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(raw, forKey: .raw)
        try container.encode(notes, forKey: .notes)
    }
}
