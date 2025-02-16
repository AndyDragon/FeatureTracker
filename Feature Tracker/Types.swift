//
//  Types.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-16.
//

import Foundation

struct CloudKitConfiguration {
    static var Enabled = false
    static var AutoSync = false
}

enum BackupOperation: CaseIterable {
    case none,
         backup,
         fileBackup,
         cloudBackup,
         restore,
         fileRestore,
         cloudRestore
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
