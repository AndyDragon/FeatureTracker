//
//  SchemaV3.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-12-23.
//

import Foundation
import SwiftData

enum SchemaV3 : VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [Page.self, Feature.self]
    }

    static var versionIdentifier: Schema.Version = .init(1, 2, 0)
}

extension SchemaV3 {
    @Model
    class Page {
        @Attribute(.unique) var id: UUID = UUID()
        var name: String = ""
        var hub: String = "snap"
        var notes: String = ""
        var count: Int = 1
        var isChallenge: Bool = false
        @Relationship(deleteRule: .cascade) var features: [Feature]? = [Feature]()

        init(id: UUID, name: String = "", hub: String = "snap", notes: String = "", count: Int = 1, isChallenge: Bool = false) {
            self.id = id
            self.name = name
            self.hub = hub
            self.notes = notes
            self.count = count
            self.isChallenge = isChallenge
        }

        init(pageV2: SchemaV2.Page) {
            self.id = pageV2.id
            self.name = pageV2.name
            self.hub = "snap"
            self.notes = pageV2.notes
            self.count = pageV2.count
            self.isChallenge = pageV2.isChallenge
        }
    }

    @Model
    class Feature {
        @Attribute(.unique) var id: UUID = UUID()
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

        init(featureV2: SchemaV2.Feature) {
            self.id = featureV2.id
            self.date = featureV2.date
            self.raw = featureV2.raw
            self.notes = featureV2.notes
        }
    }
}
