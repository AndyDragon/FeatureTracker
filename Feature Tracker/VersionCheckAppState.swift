//
//  VersionCheckAppState.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-18.
//

#if STANDALONE

import SwiftUI
import SwiftyBeaver

struct VersionManifest: Codable {
    let macOS: VersionEntry
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
    
    init(
        appVersion: String = "unknown",
        currentVersion: String = "unknown",
        linkToCurrentVersion: String = ""
    ) {
        self.appVersion = appVersion
        self.currentVersion = currentVersion
        self.linkToCurrentVersion = linkToCurrentVersion
    }
}

enum VersionCheckResult {
    case checking
    case complete
    case newAvailable
    case newRequired
    case manualCheckComplete
    case checkFailed
}

struct VersionCheckAppState {
    private var isCheckingForUpdates: Binding<Bool>
    var versionCheckResult: Binding<VersionCheckResult>
    var versionCheckToast: Binding<VersionCheckToast>
    private var versionLocation: String
    var isPreviewMode: Bool = false
    private let logger = SwiftyBeaver.self

    init(
        isCheckingForUpdates: Binding<Bool>,
        versionCheckResult: Binding<VersionCheckResult>,
        versionCheckToast: Binding<VersionCheckToast>,
        versionLocation: String
    ) {
        self.isCheckingForUpdates = isCheckingForUpdates
        self.versionCheckResult = versionCheckResult
        self.versionCheckToast = versionCheckToast
        self.versionLocation = versionLocation
    }

    func checkForUpdates(_ manualCheck: Bool = false) {
        if isPreviewMode {
            return
        }
        versionCheckResult.wrappedValue = .checking
        isCheckingForUpdates.wrappedValue = true
        Task {
            try? await checkForUpdatesAsync(manualCheck)
        }
    }

    func resetCheckingForUpdates() {
        versionCheckResult.wrappedValue = .complete
    }

    private func checkForUpdatesAsync(_ manualCheck: Bool = false) async throws -> Void {
        do {
            // Check version from server manifest
            let versionManifestUrl = URL(string: versionLocation)!
            let versionManifest = try await URLSession.shared.decode(VersionManifest.self, from: versionManifestUrl)
            if Bundle.main.releaseVersionOlder(than: versionManifest.macOS.current) {
                DispatchQueue.main.async {
                    withAnimation {
                        versionCheckToast.wrappedValue = VersionCheckToast(
                            appVersion: Bundle.main.releaseVersionNumberPretty,
                            currentVersion: versionManifest.macOS.current,
                            linkToCurrentVersion: versionManifest.macOS.link)
                        if versionManifest.macOS.vital {
                            self.logger.verbose("New required version", context: "Version")
                            versionCheckResult.wrappedValue = .newRequired
                        } else {
                            self.logger.verbose("New available version", context: "Version")
                            versionCheckResult.wrappedValue = .newAvailable
                        }
                    }
                }
                isCheckingForUpdates.wrappedValue = false
            } else {
                self.logger.verbose("Using latest version", context: "Version")
                versionCheckToast.wrappedValue = VersionCheckToast(
                    appVersion: Bundle.main.releaseVersionNumberPretty)
                versionCheckResult.wrappedValue = manualCheck ? .manualCheckComplete : .complete
                isCheckingForUpdates.wrappedValue = false
            }
        } catch {
            self.logger.error("Version check failed: \(error.localizedDescription)", context: "Version")
            debugPrint(error)
            versionCheckToast.wrappedValue = VersionCheckToast(
                appVersion: Bundle.main.releaseVersionNumberPretty)
            versionCheckResult.wrappedValue = .checkFailed
            isCheckingForUpdates.wrappedValue = false
        }
    }
}

#endif
