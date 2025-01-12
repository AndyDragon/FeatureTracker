//
//  FeatureTrackerApp.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import SwiftData
import SwiftUI

@main
struct FeatureTrackerApp: App {
    @Environment(\.openWindow) private var openWindow

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
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    // Open the "about" window using the id "about"
                    openWindow(id: "about")
                }, label: {
                    Text("About \(Bundle.main.displayName ?? "Feature Tracker")")
                })
            }
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

        // About view window with id "about"
        Window("About \(Bundle.main.displayName ?? "Feature Tracker")", id: "about") {
            AboutView(packages: [
                "CloudKitSyncMonitor": [
                    "Grant Grueninger ([Github profile](https://github.com/ggruen))"
                ],
                "SwiftDataKit": [
                    "东坡肘子 ([Github profile](https://github.com/fatbobman))"
                ],
                "ToastView-SwiftUI": [
                    "Gaurav Tak ([Github profile](https://github.com/gauravtakroro))",
                    "modified by AndyDragon ([Github profile](https://github.com/AndyDragon))"
                ]
            ])
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
    }
}
