//
//  ContentView+ViewModel.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2025-01-11.
//

import SwiftUI

extension View {
    func attachVersionCheckState(_ viewModel: ContentView.ViewModel, _ appState: VersionCheckAppState, _ launchUrl: @escaping (_ url: URL) -> Void) -> some View {
        self.onChange(of: appState.versionCheckResult.wrappedValue) {
            viewModel.handleVersionCheck(appState) { url in
                launchUrl(url)
            }
        }
    }
}

extension ContentView {
    @Observable
    class ViewModel {
        // MARK: Version check
        private var lastVersionCheckResult = VersionCheckResult.complete

        func handleVersionCheck(
            _ appState: VersionCheckAppState,
            _ launchURL: @escaping (_ url: URL) -> Void
        ) {
            if appState.versionCheckResult.wrappedValue == lastVersionCheckResult {
                return;
            }
            lastVersionCheckResult = appState.versionCheckResult.wrappedValue
            switch appState.versionCheckResult.wrappedValue {
            case .newAvailable:
                dismissAllNonBlockingToasts()
                showToast(
                    .alert,
                    "New version available",
                    String {
                        "You are using v\(appState.versionCheckToast.wrappedValue.appVersion) "
                        "and v\(appState.versionCheckToast.wrappedValue.currentVersion) is available"
                        "\(appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty ? "" : ", click Download to open your browser") "
                        "(this will go away in \(AdvancedToastStyle.alert.duration) seconds)"
                    },
                    width: 720,
                    buttonTitle: "Download",
                    onButtonTapped: {
                        if let url = URL(string: appState.versionCheckToast.wrappedValue.linkToCurrentVersion) {
                            launchURL(url)
                            let terminationTask = DispatchWorkItem {
                                NSApplication.shared.terminate(nil)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: terminationTask)
                        }
                    },
                    onDismissed: {
                        appState.resetCheckingForUpdates()
                    }
                )
                break
            case .newRequired:
                dismissAllNonBlockingToasts()
                showToast(
                    .fatal,
                    "New version required",
                    String {
                        "You are using v\(appState.versionCheckToast.wrappedValue.appVersion) "
                        "and v\(appState.versionCheckToast.wrappedValue.currentVersion) is required"
                        "\(appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty ? "" : ", click Download to open your browser") "
                        "or ⌘ + Q to Quit"
                    },
                    width: 720,
                    buttonTitle: "Download",
                    onButtonTapped: {
                        if let url = URL(string: appState.versionCheckToast.wrappedValue.linkToCurrentVersion) {
                            launchURL(url)
                            let terminationTask = DispatchWorkItem {
                                NSApplication.shared.terminate(nil)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: terminationTask)
                        }
                    }
                )
                break
            case .manualCheckComplete:
                showToast(
                    .info,
                    "Latest version",
                    "You are using the latest version v\(appState.versionCheckToast.wrappedValue.appVersion)",
                    onDismissed: {
                        appState.resetCheckingForUpdates()
                    }
                )
                break
            case .checkFailed:
                dismissAllNonBlockingToasts()
                showToast(
                    .alert,
                    "Failed to check version",
                    String {
                        "Failed to check the app version. You are using v\(appState.versionCheckToast.wrappedValue.appVersion)"
                        "(this will go away in \(AdvancedToastStyle.alert.duration) seconds)"
                    },
                    width: 720,
                    buttonTitle: "Retry",
                    onButtonTapped: {
                        appState.resetCheckingForUpdates()
                        appState.checkForUpdates()
                    },
                    onDismissed: {
                        appState.resetCheckingForUpdates()
                    }
                )
                break
            default:
                // do nothing
                break
            }
        }

        // MARK: Toasts
        var toastViews = [AdvancedToast]()
        var hasModalToasts: Bool {
            return toastViews.count(where: { $0.modal }) > 0
        }

        func dismissToast(
            _ toast: AdvancedToast
        ) {
            toastViews.removeAll(where: { $0 == toast })
        }

        func dismissAllNonBlockingToasts() {
            toastViews.removeAll(where: { !$0.blocking })
        }

        @discardableResult func showToast(
            _ type: AdvancedToastStyle,
            _ title: String,
            _ message: String,
            duration: Double? = nil,
            modal: Bool? = nil,
            blocking: Bool? = nil,
            width: CGFloat? = nil,
            buttonTitle: String? = nil,
            onButtonTapped: (() -> Void)? = nil,
            onDismissed: (() -> Void)? = nil
        ) -> AdvancedToast {
            let advancedToastView = AdvancedToast(
                type: type,
                title: title,
                message: message,
                duration: duration,
                modal: modal,
                blocking: blocking,
                width: width,
                buttonTitle: buttonTitle,
                onButtonTapped: onButtonTapped,
                onDismissed: onDismissed
            )
            toastViews.append(advancedToastView)
            while toastViews.count > 5 {
                toastViews.remove(at: 0)
            }
            return advancedToastView
        }

        @discardableResult func showSuccessToast(
            _ title: String,
            _ message: String
        ) -> AdvancedToast {
            return showToast(.success, title, message)
        }

        @discardableResult func showInfoToast(
            _ title: String,
            _ message: String
        ) -> AdvancedToast {
            return showToast(.info, title, message)
        }
    }
}
