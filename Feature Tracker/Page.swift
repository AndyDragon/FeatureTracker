//
//  Page.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import Foundation
import SwiftData

typealias Page = SchemaV3.Page

class CodablePage: Codable {
    var id: UUID = UUID()
    var name: String = ""
    var hub: String = ""
    var notes: String = ""
    var count: Int = 1
    var isChallenge: Bool = false
    var features: [CodableFeature] = [CodableFeature]()
    
    init(_ page: Page) {
        self.id = page.id
        self.name = page.name
        self.hub = page.hub
        self.notes = page.notes
        self.count = page.count
        self.isChallenge = page.isChallenge
        self.features.append(contentsOf: page.features!.sorted(by: { $0.date < $1.date }).map({ feature in
            return CodableFeature(feature)
        }))
    }
    
    func toPage() -> Page {
        let page = Page(id: id, name: name, hub: hub, notes: notes, count: count, isChallenge: isChallenge)
        page.features!.append(contentsOf: features.map({ feature in
            return feature.toFeature()
        }))
        return page
    }
    
    enum CodingKeys: CodingKey {
        case id,
             name,
             hub,
             notes,
             count,
             isChallenge,
             features
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        hub = try container.decodeIfPresent(String.self, forKey: .hub) ?? "snap"
        notes = try container.decode(String.self, forKey: .notes)
        count = try container.decode(Int.self, forKey: .count)
        isChallenge = try container.decodeIfPresent(Bool.self, forKey: .isChallenge) ?? false
        features = try container.decode([CodableFeature].self, forKey: .features)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(hub, forKey: .hub)
        try container.encode(notes, forKey: .notes)
        try container.encode(count, forKey: .count)
        try container.encode(isChallenge, forKey: .isChallenge)
        try container.encode(features.sorted { $0.date < $1.date }, forKey: .features)
    }
}
