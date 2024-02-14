//
//  Page.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import Foundation
import SwiftData

@Model
class Page: Codable, Comparable, Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var notes: String = ""
    var count: Int = 1
    @Relationship(deleteRule: .cascade) var features: [Feature]? = [Feature]()

    init(name: String = "", notes: String = "", count: Int = 1) {
        self.name = name
        self.notes = notes
        self.count = count
    }

    init(id: UUID, name: String, notes: String, count: Int) {
        self.id = id
        self.name = name
        self.notes = notes
        self.count = count
    }

    static func == (lhs: Page, rhs: Page) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func < (lhs: Page, rhs: Page) -> Bool {
        return lhs.name < rhs.name
    }
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case notes
        case count
        case features
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        notes = try container.decode(String.self, forKey: .notes)
        count = try container.decode(Int.self, forKey: .count)
        features = try container.decode([Feature].self, forKey: .features)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(notes, forKey: .notes)
        try container.encode(count, forKey: .count)
        try container.encode(features?.sorted { $0.date < $1.date }, forKey: .features)
    }
}
