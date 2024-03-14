//
//  VersionCheckAppState.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-18.
//

import SwiftUI

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
    
    init(appVersion: String = "unknown", currentVersion: String = "unknown", linkToCurrentVersion: String = "") {
        self.appVersion = appVersion
        self.currentVersion = currentVersion
        self.linkToCurrentVersion = linkToCurrentVersion
    }
}

struct VersionCheckAppState {
    private var isCheckingForUpdates: Binding<Bool>
    var isShowingVersionAvailableToast: Binding<Bool>
    var isShowingVersionRequiredToast: Binding<Bool>
    var versionCheckToast: Binding<VersionCheckToast>
    private var versionLocation: String
    
    init(
        isCheckingForUpdates: Binding<Bool>,
        isShowingVersionAvailableToast: Binding<Bool>,
        isShowingVersionRequiredToast: Binding<Bool>,
        versionCheckToast: Binding<VersionCheckToast>,
        versionLocation: String) {
            self.isCheckingForUpdates = isCheckingForUpdates
            self.isShowingVersionAvailableToast = isShowingVersionAvailableToast
            self.isShowingVersionRequiredToast = isShowingVersionRequiredToast
            self.versionCheckToast = versionCheckToast
            self.versionLocation = versionLocation
        }
    
    func checkForUpdates() {
        isCheckingForUpdates.wrappedValue = true
        Task {
            try? await checkForUpdatesAsync()
        }
    }
    
    func resetCheckingForUpdates() {
        isCheckingForUpdates.wrappedValue = false
    }
    
    private func checkForUpdatesAsync() async throws -> Void {
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
                            isShowingVersionRequiredToast.wrappedValue.toggle()
                        } else {
                            isShowingVersionAvailableToast.wrappedValue.toggle()
                        }
                    }
                }
            } else {
                resetCheckingForUpdates()
            }
        } catch {
            // do nothing, the version check is not critical
            debugPrint(error.localizedDescription)
            resetCheckingForUpdates()
        }
    }
}

