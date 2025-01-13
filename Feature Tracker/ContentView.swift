//
//  ContentView.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import CloudKitSyncMonitor
import SwiftData
import SwiftUI
import SwiftyBeaver

struct ContentView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.modelContext) var modelContext
    @Query var pages: [Page]

    @State private var viewModel = ViewModel()

    @State private var path = [Page]()
    @State private var selectedPage: Page?
    @State private var selectedFeature: Feature?
    @State private var exceptionError = ""
    @State private var backupOperation = BackupOperation.none
    @State private var showingBackupRestoreErrorAlert = false
    @State private var showSyncAccountStatus = false
    @State private var confirmationAlertTitle = ""
    @State private var confirmationAlertText = ""
    @State private var confirmationAlertAction: (() -> Void)? = nil
    @State private var showConfirmationAlert = false
    @State private var iCloudActive = false;
    @State private var iCloudError = ""
    @AppStorage("pageSorting", store: .standard) private var pageSorting = PageSorting.name
    @ObservedObject private var syncMonitor = SyncMonitor.shared

    private let appState: VersionCheckAppState
    private let logger = SwiftyBeaver.self

    init(_ appState: VersionCheckAppState) {
        self.appState = appState
    }
    
    @MainActor
    private func setAuthor(container: ModelContainer, authorName: String) {
        container.mainContext.managedObjectContext?.transactionAuthor = authorName
    }

    var body: some View {
        NavigationSplitView {
            ZStack {
                VStack {
                    PageListing(sorting: pageSorting, selectedPage: $selectedPage, selectedFeature: $selectedFeature)
                        .listStyle(.sidebar)
                        .onDeleteCommand {
                            logger.verbose("Swiped to delete page", context: "User")
                            if let page = selectedPage {
                                confirmationAlertTitle = "Confirm delete"
                                confirmationAlertText = String {
                                    "Are you sure you want to delete this page / challenge?"
                                    "This cannot be undone."
                                }
                                confirmationAlertAction = {
                                    selectedFeature = nil
                                    selectedPage = nil
                                    modelContext.delete(page)
                                    logger.verbose("Deleted page", context: "User")
                                    viewModel.showSuccessToast("Deleted page/challenge!", "Removed the page or challenge and all the features")
                                }
                                showConfirmationAlert.toggle()
                            }
                        }
                        .navigationSplitViewColumnWidth(min: 280, ideal: 320)
                        .toolbar {
                            Button("Add page", systemImage: "plus", action: addPage)
                                .disabled(viewModel.hasModalToasts)
                                .help("Add a new page to the list")
                            Menu("Sort", systemImage: "arrow.up.arrow.down") {
                                Picker("Sort pages by", selection: $pageSorting) {
                                    Text("Name").tag(PageSorting.name)
                                    Text("Count").tag(PageSorting.count)
                                    Text("Features").tag(PageSorting.features)
                                }
                                .pickerStyle(.inline)
                            }
                            .disabled(viewModel.hasModalToasts)
                            .help("Change the sorting for the list of pages")
                        }
                    if CloudKitConfiguration.Enabled {
                        HStack {
                            Image(systemName: iCloudActive ? "arrow.triangle.2.circlepath.icloud" : syncMonitor.syncStateSummary.symbolName)
                                .foregroundColor(iCloudActive ? .gray : syncMonitor.syncStateSummary.symbolColor)
                                .symbolEffect(
                                    .pulse,
                                    options: iCloudActive || syncMonitor.syncStateSummary.inProgress ? .repeating.speed(3) : .default,
                                    value: iCloudActive || syncMonitor.syncStateSummary.inProgress)
                                .symbolRenderingMode(iCloudActive || syncMonitor.syncStateSummary.inProgress ? .hierarchical : .monochrome)
                                .help(syncMonitor.syncError
                                      ? (syncMonitor.syncStateSummary.description + " " + (syncMonitor.lastError?.localizedDescription ?? "unknown"))
                                      : iCloudError.isEmpty ? syncMonitor.syncStateSummary.description : iCloudError)
                            if showSyncAccountStatus {
                                if case .accountNotAvailable = syncMonitor.syncStateSummary {
                                    Text("Not logged into iCloud account, changes will not be synced to iCloud storage")
                                }
                            }
                            Spacer()
                        }
                        .padding([.top], 4)
                        .padding([.bottom], 16)
                        .padding([.leading], 20)
                        .task {
                            do {
                                try await Task.sleep(nanoseconds: 5_000_000_000)
                                showSyncAccountStatus = true
                            } catch {}
                        }
                    } else {
                        HStack {
                            Image(systemName: iCloudActive ? "arrow.triangle.2.circlepath.icloud" : "icloud")
                                .foregroundColor(iCloudActive ? .gray : .green)
                                .symbolEffect(.pulse, options: iCloudActive ? .repeating.speed(3) : .default, value: iCloudActive)
                                .symbolRenderingMode(iCloudActive ? .hierarchical : .monochrome)
                                .help(iCloudActive ?
                                      "Busy with cloud sync" :
                                        iCloudError.isEmpty ? "Cloud sync ready" : iCloudError)
                            if iCloudActive {
                                Text("iCloud storage active...")
                            }
                            Spacer()
                        }
                        .padding([.top], 4)
                        .padding([.bottom], 16)
                        .padding([.leading], 20)
                    }
                }
            }
        } detail: {
            ZStack {
                VStack {
                    if let page = selectedPage {
                        HStack(alignment: .top) {
                            Spacer()
                            VStack(alignment: .center) {
                                let featuresCount = getFeatures()
                                let totalFeaturesCount = getTotalFeatures()
                                if (featuresCount != totalFeaturesCount) {
                                    Text("Total features: \(featuresCount) (\(totalFeaturesCount))")
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundColor(.blue)
                                        .brightness(0.3)
                                        .help("Total count including features which count more than one is \(totalFeaturesCount)")
                                } else {
                                    Text("Total features: \(featuresCount)")
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundColor(.blue)
                                        .brightness(0.3)
                                }
                            }
                            Spacer()
                            VStack(alignment: .center) {
                                let pagesCount = getPages()
                                let totalPagesCount = getTotalPages()
                                if pagesCount != totalPagesCount {
                                    Text("Total pages: \(pagesCount) (\(totalPagesCount))")
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundColor(.blue)
                                        .brightness(0.3)
                                        .help("Total count including pages which count more than one is \(totalPagesCount)")
                                } else {
                                    Text("Total pages: \(pagesCount)")
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundColor(.blue)
                                        .brightness(0.3)
                                }
                            }
                            Spacer()
                            VStack(alignment: .center) {
                                Text("Membership: \(getMembership())")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .foregroundColor(.blue)
                                    .brightness(0.3)
                            }
                            Spacer()
                        }
                        .padding([.leading, .trailing])
                        .padding([.top], 6)
                        .padding([.bottom], 7)
                        .border(.black, edges: [.bottom], width: 1)
                        .fontWeight(.bold)
                        Spacer()
                        PageEditor(page: page, selectedFeature: $selectedFeature, onDelete: {
                            logger.verbose("Tapped delete page", context: "User")
                            confirmationAlertTitle = "Confirm delete"
                            confirmationAlertText = String {
                                "Are you sure you want to delete this page / challenge?"
                                "This cannot be undone."
                            }
                            confirmationAlertAction = {
                                selectedFeature = nil
                                selectedPage = nil
                                modelContext.delete(page)
                                viewModel.showSuccessToast("Deleted page/challenge!", "Removed the page or challenge and all the features")
                                logger.verbose("Deleted the page", context: "System")
                            }
                            showConfirmationAlert.toggle()
                        }, onDeleteFeature: { feature in
                            logger.verbose("Tapped delete feature", context: "User")
                            confirmationAlertTitle = "Confirm delete"
                            confirmationAlertText = String {
                                "Are you sure you want to delete this feature?"
                                "This cannot be undone."
                            }
                            confirmationAlertAction = {
                                selectedFeature = nil
                                page.features!.remove(element: feature)
                                viewModel.showSuccessToast("Deleted feature!", "Removed the feature")
                                logger.verbose("Deleted the feature", context: "System")
                            }
                            showConfirmationAlert.toggle()
                        }, onClose: {
                            withAnimation {
                                selectedFeature = nil
                                selectedPage = nil
                            }
                        }, onCloseFeature: {
                            withAnimation {
                                selectedFeature = nil
                            }
                        })
                    } else {
                        VStack {
                            Spacer()
                            Text("Summary of features")
                                .fontWeight(.bold)
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                                .brightness(0.3)
                                .padding([.bottom])
                            Text(getFeaturesSummary())
                                .fontWeight(.bold)
                                .font(.system(size: 24))
                                .padding([.bottom])
                            Text(getPagesSummary())
                                .fontWeight(.bold)
                                .font(.system(size: 24))
                                .padding([.bottom])
                            Text(getMembershipSummary())
                                .fontWeight(.black)
                                .font(.system(size: 24))
                            Spacer()
                            Text("Select page from the list to edit")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
            }
            .toolbar {
                Button("Populate defaults", action: {
                    logger.verbose("Tapped populate defaults", context: "User")
                    confirmationAlertTitle = "Confirm reset to defaults"
                    confirmationAlertText = String {
                        "Are you sure you want to restore everything to the defaults?"
                        "This cannot be undone!"
                    }
                    showConfirmationAlert.toggle()
                })
                .disabled(viewModel.hasModalToasts)
                .help("Populate the default list of pages")

                Button("Generate report", systemImage: "menucard", action: generateReport)
                    .disabled(viewModel.hasModalToasts)
                    .help("Generate a report of features for Snap Management")

                Menu("JSON", systemImage: "tray") {
                    Section(header: Text("Backup to:")) {
                        Button(action: backup) {
                            Label("Clipboard", systemImage: "tray.and.arrow.down")
                        }
                        Button(action: backupToCloud) {
                            Label("iCloud Documents", systemImage: "icloud.and.arrow.up")
                        }
                    }
                    Section(header: Text("Restore from:")) {
                        Button(action: {
                            confirmationAlertTitle = "Confirm restore"
                            confirmationAlertText = String {
                                "Are you sure you want to restore from clipboard?"
                                "This cannot be undone!"
                            }
                            confirmationAlertAction = {
                                restore()
                            }
                            showConfirmationAlert.toggle()
                        }) {
                            Label("Clipboard", systemImage: "tray.and.arrow.up")
                        }
                        Button(action: {
                            confirmationAlertTitle = "Confirm restore"
                            confirmationAlertText = String {
                                "Are you sure you want to restore from iCloud?"
                                "This cannot be undone!"
                            }
                            confirmationAlertAction = {
                                restoreFromCloud()
                            }
                            showConfirmationAlert.toggle()
                        }) {
                            Label("iCloud Documents", systemImage: "icloud.and.arrow.down")
                        }
                    }
                }
                .disabled(viewModel.hasModalToasts)
                .help("Backup or restore the current features")
            }
        }
        .advancedToastView(toasts: $viewModel.toastViews)
        .attachVersionCheckState(viewModel, appState) { url in
            openURL(url)
        }
        .alert(
            confirmationAlertTitle,
            isPresented: $showConfirmationAlert,
            actions: {
                Button(role: .destructive, action: confirmationAlertAction ?? { }) {
                    Text("Yes")
                }
            },
            message: {
                Text(confirmationAlertText)
            }
        )
        .alert(
            getBackupOperationError(backupOperation),
            isPresented: $showingBackupRestoreErrorAlert,
            actions: {
                Button(action: {
                    showingBackupRestoreErrorAlert.toggle()
                }) {
                    Text("OK")
                }
            },
            message: {
                Text(getBackupOperationErrorMessage(backupOperation, exceptionError))
                .accentColor(.red)
            }
        )
        .task {
            appState.checkForUpdates()
        }
    }
    
    func getBackupOperationError(_ operation: BackupOperation) -> String {
        switch operation {
        case .backup:
            return "ERROR: Failed to backup"
        case .cloudBackup:
            return "ERROR: Failed to backup to your iCloud"
        case .restore:
            return "ERROR: Failed to restore"
        case .cloudRestore:
            return "ERROR: Failed to restore from your iCloud"
        case .none:
            break
        }
        return "ERROR"
    }
    
    func getBackupOperationErrorMessage(_ operation: BackupOperation, _ message: String) -> String {
        switch operation {
        case .backup:
            return "Could to backup to the clipboard: \(message)"
        case .cloudBackup:
            return "Could to backup to your iCloud documents: \(message)"
        case .restore:
            return "Could to restore from the clipboard: \(message)"
        case .cloudRestore:
            return "Could to restore from your iCloud documents: \(message)"
        case .none:
            break
        }
        return message
    }
    
    func addPage() -> Void {
        logger.verbose("Tapped to add page", context: "User")
        withAnimation {
            let newPage = Page(id: UUID(), name: "new page")
            modelContext.insert(newPage)
            selectedPage = newPage
            logger.verbose("Added new page", context: "System")
        }
    }

    func getFeatures() -> Int {
        var total = 0
        for page in pages {
            total += page.features!.count
        }
        return total
    }

    func getTotalFeatures() -> Int {
        var total = 0
        for page in pages {
            total += page.features!.count * page.count
        }
        return total
    }

    func getPages() -> Int {
        var total = 0
        for page in pages {
            total += page.features!.isEmpty ? 0 : 1
        }
        return total
    }

    func getTotalPages() -> Int {
        var total = 0
        for page in pages {
            total += page.features!.isEmpty ? 0 : page.count
        }
        return total
    }

    func getMembership() -> String {
        let features = getTotalFeatures()
        let pages = getTotalPages()
        if (features < 5) {
            return "Artist"
        }
        if (features < 15) {
            return "Member"
        }
        if (pages < 15) {
            return "VIP Member"
        }
        if (pages < 35) {
            return "VIP Gold Member"
        }
        if (pages < 55) {
            return "Platinum Member"
        }
        if (pages < 80) {
            return "Elite Member"
        }
        return "Hall of Fame Member"
    }

    func copyToClipboard(_ text: String) -> Void {
#if os(iOS)
        UIPasteboard.general.string = text
#else
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.writeObjects([text as NSString])
#endif
    }

    func getStringForCount(_ count: Int, _ countLabel: String) -> String {
        if count == 1 {
            return "\(count) \(countLabel)"
        }
        return "\(count) \(countLabel)s"
    }
    
    func getFeaturesSummary() -> String {
        let featuresCount = getFeatures()
        let totalFeaturesCount = getTotalFeatures()
        if (featuresCount != totalFeaturesCount) {
            return "Total features: \(featuresCount) (counts as \(totalFeaturesCount))"
        }
        return "Total features: \(featuresCount)"
    }
    
    func getPagesSummary() -> String {
        let pagesCount = getPages()
        let totalPagesCount = getTotalPages()
        if (pagesCount != totalPagesCount) {
            return "Total pages with features: \(pagesCount) (counts as \(totalPagesCount))"
        }
        return "Total pages with features: \(pagesCount)"
    }
    
    func getMembershipSummary() -> String {
        return "Membership level: \(getMembership())"
    }

    func generateReport() -> Void {
        logger.verbose("Tapped generate report", context: "User")
        var lines = [String]()
        lines.append("Report of features")
        lines.append("------------------")
        lines.append("")
        lines.append(getFeaturesSummary())
        lines.append("")
        lines.append(getPagesSummary())
        lines.append("")
        lines.append(getMembershipSummary())
        for page in pages.sorted(by: { left, right in
            if pageSorting == .name {
                return left.name < right.name
            } else if pageSorting == .count {
                if left.count == right.count {
                    return left.name < right.name
                }
                return left.count > right.count
            } else if pageSorting == .features {
                if left.features?.count == right.features?.count {
                    return left.name < right.name
                }
                return (left.features?.count ?? 0) > (right.features?.count ?? 0);
            }
            return left.name < right.name
        }) {
            if page.features!.count > 0 {
                lines.append("")
                if page.count != 1 {
                    lines.append("Page: \(page.name.uppercased()) - \(getStringForCount(page.features!.count, "feature")) (counts as \(page.features!.count * page.count))")
                } else {
                    lines.append("Page: \(page.name.uppercased()) - \(getStringForCount(page.features!.count, "feature"))")
                }
                for feature in page.features!.sorted(by: { $0.date > $1.date }) {
                    lines.append("\tFeature: \(feature.date.formatted(date: .complete, time: .omitted)) on \(feature.raw ? "RAW" : "Snap"):")
                    lines.append("\t\t\(feature.notes)")
                }
            }
        }
        var text = ""
        for line in lines { text = text + line + "\n" }
        copyToClipboard(text)
        viewModel.showSuccessToast("Report generated!", "Copied the report of features to the clipboard")
        logger.verbose("Generated report", context: "System")
    }
    
    func backup() -> Void {
        logger.verbose("Tapped backup to clipboard", context: "User")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            var codablePages = [CodablePage]()
            codablePages.append(contentsOf: pages.sorted(by: { $0.name < $1.name }).map({ page in
                return CodablePage(page)
            }))
            let json = try encoder.encode(codablePages)
            copyToClipboard(String(decoding: json, as: UTF8.self))
            viewModel.showSuccessToast("Backed up!", "Copied a backup of the pages and features to the clipboard")
            logger.verbose("Backed up to clipboard", context: "System")
        } catch {
            logger.error("Failed to backup to clipboard: \(error.localizedDescription)", context: "System")
            exceptionError = error.localizedDescription
            backupOperation = .backup
            showingBackupRestoreErrorAlert.toggle()
        }
    }

    func backupToCloud() -> Void {
        withAnimation {
            iCloudActive = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: { @MainActor in
            logger.verbose("Tapped backup to iCloud", context: "User")
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
                encoder.dateEncodingStrategy = .iso8601
                var codablePages = [CodablePage]()
                codablePages.append(contentsOf: pages.sorted(by: { $0.name < $1.name }).map({ page in
                    return CodablePage(page)
                }))
                let json = try encoder.encode(codablePages)
                if let containerUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
                    if !FileManager.default.fileExists(atPath: containerUrl.path, isDirectory: nil) {
                        try FileManager.default.createDirectory(at: containerUrl, withIntermediateDirectories: true, attributes: nil)
                    }
                    
                    let fileUrl = containerUrl.appendingPathComponent("features.json")
                    try String(decoding: json, as: UTF8.self).write(to: fileUrl, atomically: true, encoding: .utf8)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: { @MainActor in
                        viewModel.showSuccessToast("Backed up to iCloud!", "Stored a backup of the pages and features to your iCloud documents")
                        logger.verbose("Backed up to iCloud", context: "System")
                    })
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: { @MainActor in
                        if (iCloudActive) {
                            withAnimation {
                                iCloudActive.toggle()
                            }
                        }
                    })
                } else {
                    showCloudBackupErrorToast("No access to your iCloud documents")
                    logger.warning("No access to your iCloud", context: "System")
                }
            } catch {
                showCloudBackupErrorToast(error.localizedDescription)
            }
        })
    }

    func showCloudBackupErrorToast(_ message: String) {
        logger.error("Failed to backup to iCloud: \(message)", context: "System")
        debugPrint("iCloud backup failed: \(message)")
        exceptionError = message
        iCloudError = exceptionError
        iCloudActive = false
        backupOperation = .cloudBackup
        showingBackupRestoreErrorAlert.toggle()
    }

    func restore() -> Void {
        logger.verbose("Tapped restore from clipboard", context: "User")
        do {
            let pasteBoard = NSPasteboard.general
            let json = pasteBoard.string(forType: .string) ?? ""
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let codablePages = try decoder.decode([CodablePage].self, from: json.data(using: .utf8)!)
            if codablePages.count != 0 {
                do {
                    try modelContext.delete(model: Page.self)
                } catch {
                    // do nothing
                    logger.error("Failed to delete a page during restore", context: "System")
                    debugPrint(error.localizedDescription)
                }
                for codablePage in codablePages {
                    modelContext.insert(codablePage.toPage())
                }
                logger.verbose("Restored from clipboard", context: "System")
                viewModel.showSuccessToast("Restored!", "Restored the items from the clipboard")
            }
        } catch let DecodingError.dataCorrupted(context) {
            showRestoreErrorToast(context.debugDescription)
        } catch let DecodingError.keyNotFound(key, context) {
            showRestoreErrorToast("Key '\(key)' not found:" + context.debugDescription)
        } catch let DecodingError.valueNotFound(value, context) {
            showRestoreErrorToast("Value '\(value)' not found:" + context.debugDescription)
        } catch let DecodingError.typeMismatch(type, context) {
            showRestoreErrorToast("Type '\(type)' mismatch:" + context.debugDescription)
        } catch {
            showRestoreErrorToast(error.localizedDescription)
        }
    }
    
    func showRestoreErrorToast(_ message: String) {
        logger.error("Failed to restore from clipboard: \(message)", context: "System")
        debugPrint("iCloud restore failed: \(message)")
        exceptionError = message
        backupOperation = .restore
        showingBackupRestoreErrorAlert.toggle()
    }
    
    func restoreFromCloud() -> Void {
        withAnimation {
            iCloudActive = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: { @MainActor in
            logger.verbose("Tapped restore from iCloud", context: "User")
            do {
                if let containerUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
                    if FileManager.default.fileExists(atPath: containerUrl.path, isDirectory: nil) {
                        let fileUrl = containerUrl.appendingPathComponent("features.json")
                        if FileManager.default.fileExists(atPath: fileUrl.path) {
                            let fileContents = FileManager.default.contents(atPath: fileUrl.path)
                            if let json = fileContents {
                                let decoder = JSONDecoder()
                                decoder.dateDecodingStrategy = .iso8601
                                let codablePages = try decoder.decode([CodablePage].self, from: json)
                                if codablePages.count != 0 {
                                    do {
                                        try modelContext.delete(model: Feature.self)
                                        try modelContext.delete(model: Page.self)
                                        try modelContext.save()
                                    } catch {
                                        logger.error("Failed to reset store during restore: \(error.localizedDescription)", context: "System")
                                        debugPrint("Failed to reset store:")
                                        debugPrint(error.localizedDescription)
                                        // TODO andydragon : should be show an alert and stop the restore?
                                    }
                                    for codablePage in codablePages {
                                        modelContext.insert(codablePage.toPage())
                                    }
                                    do {
                                        try modelContext.save()
                                    } catch {
                                        // do nothing
                                        logger.error("Failed to save store after restore: \(error.localizedDescription)", context: "System")
                                        debugPrint("Failed to save store after restore:")
                                        debugPrint(error.localizedDescription)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: { @MainActor in
                                        viewModel.showSuccessToast("Restored from iCloud!", "Restored the items from your iCloud")
                                        logger.verbose("Restored from clipboard", context: "System")
                                    })
                                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: { @MainActor in
                                        if (iCloudActive) {
                                            withAnimation {
                                                iCloudActive.toggle()
                                            }
                                        }
                                    })
                                } else {
                                    showCloudRestoreErrorToast("No pages found in the backup")
                                }
                            } else {
                                showCloudRestoreErrorToast("No pages loaded from the backup")
                            }
                        } else {
                            showCloudRestoreErrorToast("No backup was found in your iCloud documents")
                        }
                    } else {
                        showCloudRestoreErrorToast("No backup was found in your iCloud documents")
                    }
                } else {
                    showCloudRestoreErrorToast("No access to your iCloud documents")
                }
            } catch let DecodingError.dataCorrupted(context) {
                showCloudRestoreErrorToast(context.debugDescription)
            } catch let DecodingError.keyNotFound(key, context) {
                showCloudRestoreErrorToast("Key '\(key)' not found:" + context.debugDescription)
            } catch let DecodingError.valueNotFound(value, context) {
                showCloudRestoreErrorToast("Value '\(value)' not found:" + context.debugDescription)
            } catch let DecodingError.typeMismatch(type, context) {
                showCloudRestoreErrorToast("Type '\(type)' mismatch:" + context.debugDescription)
            } catch {
                showCloudRestoreErrorToast(error.localizedDescription)
            }
        })
    }
                                
    func showCloudRestoreErrorToast(_ message: String) {
        logger.error("Failed to restore from clipboard: \(message)", context: "System")
        debugPrint("iCloud restore failed: \(message)")
        exceptionError = message
        iCloudError = exceptionError
        iCloudActive = false
        backupOperation = .cloudRestore
        showingBackupRestoreErrorAlert.toggle()
    }

    func populateDefaultPages() -> Void {
        do {
            try modelContext.delete(model: Page.self)
        } catch {
            logger.error("Failed to reset the store: \(error.localizedDescription)", context: "System")
            // TODO andydragon : should we show an alert and stop this reset?
        }
        // Add regular pages.
        let singleFeaturePages = [
            "abandoned",
            "abstract",
            "africa",
            "ai",
            "allblack",
            "allnature",
            "allsports",
            "alltrees",
            "allwhite",
            "architecture",
            "artgallery",
            "asia",
            "australia",
            "beaches",
            "birds",
            "blue",
            "bnw",
            "books",
            "bridges",
            "butterflies",
            "canada",
            "cats",
            "china",
            "cityscape",
            "cocktails",
            "coffee",
            "collage",
            "colorsplash",
            "colours",
            "community_member",
            "communityarts",
            "country",
            "cuteness",
            "depthoffield",
            "drone",
            "drops",
            "edit",
            "europe",
            "filmphoto",
            "fishing",
            "flatlays",
            "flowers",
            "foggy",
            "france",
            "gardening",
            "germany",
            "herpetology",
            "hikes",
            "homestyle",
            "horses",
            "india",
            "insects",
            "ireland",
            "kitchen",
            "landscape",
            "lighthouses",
            "longexposure",
            "macro",
            "middleeast",
            "minimal",
            "mobile",
            "moody",
            "mountains",
            "nightshots",
            "nordic",
            "numbers",
            "oceanlife",
            "people",
            "pets",
            "potd",
            "reflection",
            "seasons",
            "silhouette",
            "skies",
            "street",
            "surreal",
            "symmetry",
            "tattoos",
            "textures",
            "thailand",
            "toys",
            "transports",
            "uae",
            "uk",
            "usa",
            "waters",
            "weddings",
            "wildlife",
            "world",
            "writings",
        ]
        for pageName in singleFeaturePages {
            modelContext.insert(Page(id: UUID(), name: pageName))
        }
        // Add the multi-count features.
        modelContext.insert(Page(id: UUID(), name: "papanoel", count: 3))
        logger.verbose("Populated the defaults", context: "System")
    }
}
