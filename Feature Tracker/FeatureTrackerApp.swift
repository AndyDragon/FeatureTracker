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

#if STANDALONE
    @State var checkingForUpdates = false
    @State var versionCheckResult: VersionCheckResult = .complete
    @State var versionCheckToast = VersionCheckToast()
#endif

    let logger = SwiftyBeaver.self
    let loggerConsole = ConsoleDestination()
    let loggerFile = FileDestination()

    init() {
        loggerConsole.logPrintWay = .logger(subsystem: "Main", category: "UI")
        loggerFile.logFileURL = getDocumentsDirectory().appendingPathComponent("\(Bundle.main.displayName ?? "Feature Tracker").log", conformingTo: .log)
        print(loggerFile.logFileURL!)
        logger.addDestination(loggerConsole)
        logger.addDestination(loggerFile)
    }

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
#if STANDALONE
        let appState = VersionCheckAppState(
            isCheckingForUpdates: $checkingForUpdates,
            versionCheckResult: $versionCheckResult,
            versionCheckToast: $versionCheckToast,
            versionLocation: "https://vero.andydragon.com/static/data/featuretracker/version.json")
#endif
        let dataProvider = DataProvider.shared
        WindowGroup {
#if STANDALONE
            ContentView(appState)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
#else
            ContentView()
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
#if SCREENSHOT
                .frame(width: 1280, height: 748)
                .frame(minWidth: 1280, maxWidth: 1280, minHeight: 748, maxHeight: 748)
#else
                .frame(minWidth: 1024, minHeight: 512)
#endif
#endif
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
#if STANDALONE
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
#endif
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

    class AppDelegate: NSObject, NSApplicationDelegate {
        private let logger = SwiftyBeaver.self

        func applicationWillFinishLaunching(_ notification: Notification) {
            logger.info("==============================================================================")
            logger.info("Start of session")
        }

        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return true
        }

        func applicationWillTerminate(_ notification: Notification) {
            logger.info("End of session")
            logger.info("==============================================================================")
        }
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
