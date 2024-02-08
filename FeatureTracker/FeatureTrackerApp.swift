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
//#if DEBUG
//            // Use an autorelease pool to make sure Swift deallocates the persistent
//            // container before setting up the SwiftData stack.
//            try autoreleasepool {
//                let desc = NSPersistentStoreDescription(url: config.url)
//                let opts = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.FeatureTracker.Pages")
//                desc.cloudKitContainerOptions = opts
//                // Load the store synchronously so it completes before initializing the
//                // CloudKit schema.
//                desc.shouldAddStoreAsynchronously = false
//                if let mom = NSManagedObjectModel(models: Page.self, Feature.self) {
//                    let container = NSPersistentCloudKitContainer(name: "Pages", managedObjectModel: mom)
//                    container.persistentStoreDescriptions = [desc]
//                    container.loadPersistentStores {_, err in
//                        if let err {
//                            fatalError(err.localizedDescription)
//                        }
//                    }
//                    // Initialize the CloudKit schema after the store finishes loading.
//                    try container.initializeCloudKitSchema()
//                    // Remove and unload the store from the persistent container.
//                    if let store = container.persistentStoreCoordinator.persistentStores.first {
//                        try container.persistentStoreCoordinator.remove(store)
//                    }
//                }
//            }
//#endif
            modelContainer = try ModelContainer(for: Page.self, Feature.self, configurations: config)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
