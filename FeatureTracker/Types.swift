//
//  Types.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-16.
//

import Foundation

struct CloudKitConfiguration {
#if CLOUDSYNC
    static var Enabled = true
#else
    static var Enabled = false
#endif
}

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

struct VersionCheckToast {
    var appVersion: String
    var currentVersion: String
    var linkToCurrentVersion: String
    
    init(appVersion: String = "unknown", currentVersion: String = "unknown", linkToCurrentVersion: String = "") {
        self.appVersion = appVersion
        self.currentVersion = currentVersion
        self.linkToCurrentVersion = linkToCurrentVersion
    }
}

class DuplicatePages {
    private var duplicateMap = [String:[Page]]()
    
    init() { }
    
    var isEmpty: Bool {
        return duplicateMap.isEmpty
    }
    
    var firstPageName: String {
        duplicateMap.keys.first ?? ""
    }
    
    func hasPage(pageName: String) -> Bool {
        return duplicateMap.keys.contains(where: { key in
            key == pageName
        });
    }
    
    func duplicateList(pageName: String) -> [Page] {
        return duplicateMap[pageName] ?? [Page]()
    }
    
    func setDuplicateList(pageName: String, duplicateList: [Page]) -> Void {
        duplicateMap[pageName] = duplicateList
    }
    
    func removeDuplicateList(pageName: String) -> Void {
        duplicateMap.removeValue(forKey: pageName)
    }
    
    func clear() -> Void {
        duplicateMap.removeAll()
    }
}
