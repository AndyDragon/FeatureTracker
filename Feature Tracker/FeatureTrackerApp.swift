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
    @State var checkingForUpdates = false
    @State var versionCheckResult: VersionCheckResult = .complete
    @State var versionCheckToast = VersionCheckToast()
    
    var body: some Scene {
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            versionCheckResult: $versionCheckResult,
            versionCheckToast: $versionCheckToast,
            versionLocation: "https://vero.andydragon.com/static/data/featuretracker/version.json")
        let dataProvider = DataProvider.share
        WindowGroup {
            ContentView(appState)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .modelContainer(dataProvider.container)
        .commands {
            CommandGroup(replacing: .appSettings, addition: {
                Button(action: {
                    appState.checkForUpdates(true)
                }, label: {
                    Text("Check for updates...")
                })
                .disabled(checkingForUpdates)
            })
            CommandGroup(replacing: CommandGroupPlacement.newItem) { }
        }
    }
}
