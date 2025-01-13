//
//  FeatureTrackerApp.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import SwiftData
import SwiftUI
import SwiftyBeaver

@main
struct FeatureTrackerApp: App {
    @Environment(\.openWindow) private var openWindow

    @State var checkingForUpdates = false
    @State var versionCheckResult: VersionCheckResult = .complete
    @State var versionCheckToast = VersionCheckToast()

    let logger = SwiftyBeaver.self
    let loggerConsole = ConsoleDestination()
    let loggerFile = FileDestination()

    init() {
        loggerConsole.logPrintWay = .logger(subsystem: "Main", category: "UI")
        loggerFile.logFileURL = getDocumentsDirectory().appendingPathComponent("\(Bundle.main.displayName ?? "Feature Tracker").log", conformingTo: .log)
        print(loggerFile.logFileURL!)
        logger.addDestination(loggerConsole)
        logger.addDestination(loggerFile)
        logger.info("==============================================================================")
        logger.info("Start of session")
    }

    var body: some Scene {
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            versionCheckResult: $versionCheckResult,
            versionCheckToast: $versionCheckToast,
            versionLocation: "https://vero.andydragon.com/static/data/featuretracker/version.json")
        let dataProvider = DataProvider.shared
        WindowGroup {
            ContentView(appState)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
                .onDisappear {
                    logger.info("End of session")
                    logger.info("==============================================================================")
                }
        }
        .modelContainer(dataProvider.container)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    logger.verbose("Open about view", context: "User")

                    // Open the "about" window using the id "about"
                    openWindow(id: "about")
                }, label: {
                    Text("About \(Bundle.main.displayName ?? "Feature Tracker")")
                })
            }
            CommandGroup(replacing: .appSettings, addition: {
                Button(action: {
                    logger.verbose("Manual check for updates", context: "User")

                    // Manually check for updates
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
                "SwiftyBeaver": [
                    "SwiftyBeaver ([Github profile](https://github.com/SwiftyBeaver))"
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

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
