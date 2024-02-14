//
//  Helpers.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-13.
//

import Foundation

extension Array where Element: Equatable {

    // Remove item from array by element
    @discardableResult
    mutating func remove(element: Element) -> Element? {
        guard let index = firstIndex(of: element) else { return nil }
        return remove(at: index)
    }
}
