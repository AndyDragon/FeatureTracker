//
//  SchemaV1.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-12-23.
//

import Foundation
import SwiftData

enum SchemaV1 : VersionedSchema {
    static var models: [any PersistentModel.Type] {
        [Page.self, Feature.self]
    }

    static var versionIdentifier: Schema.Version = .init(1, 0, 0)
}

extension SchemaV1 {
    @Model
    class Page {
        var id: UUID = UUID()
        var name: String = ""
        var notes: String = ""
        var count: Int = 1
        var isChallenge: Bool = false
        @Relationship(deleteRule: .cascade) var features: [Feature]? = [Feature]()

        init(id: UUID, name: String = "", notes: String = "", count: Int = 1, isChallenge: Bool = false) {
            self.id = id
            self.name = name
            self.notes = notes
            self.count = count
            self.isChallenge = isChallenge
        }
    }

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
}
