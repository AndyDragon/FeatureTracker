//
//  FeatureTrackerApp.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import SwiftData
import SwiftUI

@main
struct FeatureTrackerApp: App {
    private var modelContainer: ModelContainer
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
    
    init() {
        let config = ModelConfiguration()
        do {
            modelContainer = try ModelContainer(for: Page.self, Feature.self, configurations: config)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
