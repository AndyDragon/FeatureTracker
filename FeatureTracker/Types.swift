//
//  Types.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-16.
//

import Foundation

enum BackupOperation: Int, Codable, CaseIterable {
    case none,
         backup,
         restore
}

struct VersionManifest: Codable {
    let macOS: VersionEntry
    //let windows: VersionEntry
}

struct VersionEntry: Codable {
    let current: String
    let link: String
    let vital: Bool
}
