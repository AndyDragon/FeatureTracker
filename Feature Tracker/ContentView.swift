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
    @State private var iCloudActive = false
    @State private var iCloudError = ""
    @State private var showBackupExporter = false
    @State private var showRestoreImporter = false
    @State private var backupDocument = BackupDocument()
    @AppStorage("pageSorting", store: .standard) private var pageSorting = PageSorting.name
    @ObservedObject private var syncMonitor = SyncMonitor.shared

    private let logger = SwiftyBeaver.self

    private var fileNameDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

#if STANDALONE
    private let appState: VersionCheckAppState

    init(_ appState: VersionCheckAppState) {
        self.appState = appState
    }
#endif

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

                    CloudSyncView()
                }
            }
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
        } detail: {
            ZStack {
                VStack {
                    if let page = selectedPage {
                        PageEditorView(page)
                    } else {
                        ScrollView {
                            VStack {
                                TotalSummaryView()
                                ForEach(getHubs().sorted(by: { getFeatures($0) > getFeatures($1) }), id: \.self) { hub in
                                    HubSummaryView(hub)
                                }
                                Text("Select page from the list to edit")
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                // Restore importer
                HStack { }
                    .frame(width: 0, height: 0)
                    .fileImporter(
                        isPresented: $showRestoreImporter,
                        allowedContentTypes: [.json]
                    ) { result in
                        switch result {
                        case let .success(file):
                            restoreFromFile(from: file)
                        case let .failure(error):
                            debugPrint(error.localizedDescription)
                        }
                    }
                    .fileDialogConfirmationLabel("Open backup")

                // Backup exporter
                HStack { }
                    .frame(width: 0, height: 0)
                    .fileExporter(
                        isPresented: $showBackupExporter,
                        document: backupDocument,
                        contentType: .json,
                        defaultFilename: "Feature Tracker backup - \(fileNameDateFormatter.string(from: Date.now)).json"
                    ) { result in
                        switch result {
                        case .success(_):
                            logger.verbose("Saved the backup to file", context: "System")
                            viewModel.showSuccessToast("Saved backup to file", "Save the backup of your features to the file")
                        case let .failure(error):
                            debugPrint(error.localizedDescription)
                        }
                    }
                    .fileExporterFilenameLabel("Save backup as: ") // filename label
                    .fileDialogConfirmationLabel("Save backup")
            }
            .toolbar {
                MenuButton(action: {
                    logger.verbose("Tapped populate defaults", context: "User")
                    confirmationAlertTitle = "Confirm reset to defaults"
                    confirmationAlertText = String {
                        "Are you sure you want to restore everything to the defaults?"
                        "This cannot be undone!"
                    }
                    confirmationAlertAction = {
                        populateDefaultPages()
                        viewModel.showSuccessToast("Populated defaults!", "Restored the default list of pages")
                    }
                    showConfirmationAlert.toggle()
                }, text: "Populate defaults", systemImage: "lock.rotation")
                    .disabled(viewModel.hasModalToasts)
                    .help("Populate the default list of pages")

                Menu("Report", systemImage: "menucard") {
                    Section(header: Text("Hubs")) {
                        ForEach(getHubs().sorted(by: <), id: \.self) { hub in
                            MenuButton(action: { generateReportForHub(hub) }, text: "Generate report for \(hub.lowercased())", systemImage: "menucard.fill")
                                .disabled(viewModel.hasModalToasts)
                                .help("Generate a report of features for the \(hub) hub")
                        }
                    }
                    Section(header: Text("Lone pages")) {
                        ForEach(getLonePages().sorted(by: <), id: \.self) { page in
                            MenuButton(action: { generateReportForPage(page) }, text: "Generate report for \(page.lowercased())", systemImage: "menucard")
                                .disabled(viewModel.hasModalToasts)
                                .help("Generate a report of features for the \(page) page")
                        }
                    }
                }
                .disabled(viewModel.hasModalToasts)
                .help("Generate a report of features for a hub")

                Menu("JSON", systemImage: "tray") {
                    Section(header: Text("Backup to:")) {
                        MenuButton(action: backup, text: "Clipboard", systemImage: "tray.and.arrow.down")
                            .disabled(viewModel.hasModalToasts)
                        MenuButton(action: {
                            backupDocument = backupToFile()
                            showBackupExporter.toggle()
                        }, text: "File", systemImage: "arrow.up.document")
                            .disabled(viewModel.hasModalToasts)
                        MenuButton(action: backupToCloud, text: "iCloud documents", systemImage: "icloud.and.arrow.up")
                            .disabled(viewModel.hasModalToasts)
                    }
                    Section(header: Text("Restore from:")) {
                        MenuButton(action: {
                            confirmationAlertTitle = "Confirm restore"
                            confirmationAlertText = String {
                                "Are you sure you want to restore from clipboard?"
                                "This cannot be undone!"
                            }
                            confirmationAlertAction = {
                                restore()
                            }
                            showConfirmationAlert.toggle()
                        }, text: "Clipboard", systemImage: "tray.and.arrow.up")
                            .disabled(viewModel.hasModalToasts)
                        MenuButton(action: { showRestoreImporter.toggle() }, text: "File", systemImage: "arrow.down.document")
                            .disabled(viewModel.hasModalToasts)
                        MenuButton(action: {
                            confirmationAlertTitle = "Confirm restore"
                            confirmationAlertText = String {
                                "Are you sure you want to restore from iCloud?"
                                "This cannot be undone!"
                            }
                            confirmationAlertAction = {
                                restoreFromCloud()
                            }
                            showConfirmationAlert.toggle()
                        }, text: "iCloud document", systemImage: "icloud.and.arrow.down")
                            .disabled(viewModel.hasModalToasts)
                    }
                }
                .help("Backup or restore the current features")
            }
        }
        .advancedToastView(toasts: $viewModel.toastViews)
#if STANDALONE
        .navigationTitle("Feature Tracker - Standalone Version")
        .attachVersionCheckState(viewModel, appState) { url in
            openURL(url)
        }
#else
        .navigationTitle("Feature Tracker")
#endif
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
#if STANDALONE
            appState.checkForUpdates()
#endif
        }
    }

    fileprivate func CloudSyncView() -> some View {
        VStack {
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
                        try await Task.sleep(nanoseconds: 5000000000)
                        showSyncAccountStatus = true
                    } catch {}
                }
            } else {
                HStack {
                    Image(systemName: iCloudActive ? "arrow.triangle.2.circlepath.icloud" : "icloud")
                        .foregroundColor(iCloudActive ? .gray : .green)
                        .symbolEffect(.pulse, options: iCloudActive ? .repeating.speed(3) : .default, value: iCloudActive)
                        .symbolRenderingMode(iCloudActive ? .hierarchical : .monochrome)
                        .help(iCloudActive
                            ? "Busy with cloud sync"
                            : iCloudError.isEmpty
                            ? "Cloud sync ready"
                            : iCloudError)
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

    fileprivate func PageEditorView(_ page: Page) -> some View {
        VStack {
            HStack(alignment: .top) {
                Spacer()
                VStack(alignment: .center) {
                    let featuresCount = getFeatures(page.hub)
                    let totalFeaturesCount = getTotalFeatures(page.hub)
                    if featuresCount != totalFeaturesCount {
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
                    let pagesCount = getPages(page.hub)
                    let totalPagesCount = getTotalPages(page.hub)
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
                    Text("Membership: \(getMembership(page.hub))")
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
        }
    }

    fileprivate func HubSummaryView(_ hub: String) -> some View {
        VStack {
            Spacer()
            Text("Summary of features for \(hub.uppercased())")
                .fontWeight(.bold)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .brightness(0.3)
                .padding([.bottom], 8)
            Text(getFeaturesSummary(hub))
                .fontWeight(.bold)
                .font(.system(size: 16))
                .padding([.bottom], 8)
            Text(getPagesSummary(hub))
                .fontWeight(.bold)
                .font(.system(size: 16))
                .padding([.bottom], 8)
            if hasMembershipLevels(hub) {
                Text(getMembershipSummary(hub))
                    .fontWeight(.black)
                    .font(.system(size: 16))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
        .padding()
    }

    fileprivate func TotalSummaryView() -> some View {
        VStack {
            Spacer()
            Text("Summary of all features")
                .fontWeight(.bold)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .brightness(0.3)
                .padding([.bottom], 8)
            Text(getFeaturesSummary())
                .fontWeight(.bold)
                .font(.system(size: 16))
                .padding([.bottom], 8)
            Text(getPagesSummary())
                .fontWeight(.bold)
                .font(.system(size: 16))
                .padding([.bottom], 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
        .padding()
    }

    private func getHubs() -> Set<String> {
        var hubs = Set<String>()
        pages.forEach { page in
            if !page.hub.isEmpty && !hubs.contains(page.hub) && getFeatures(page.hub) != 0 {
                hubs.insert(page.hub.lowercased())
            }
        }
        return hubs
    }

    private func getLonePages() -> Set<String> {
        var lonePages = Set<String>()
        pages.forEach { page in
            if page.hub.isEmpty && page.features!.count != 0 {
                lonePages.insert(page.name.lowercased())
            }
        }
        return lonePages
    }

    private func getBackupOperationError(_ operation: BackupOperation) -> String {
        switch operation {
        case .backup:
            return "ERROR: Failed to backup"
        case .fileBackup:
            return "ERROR: Failed to backup to file"
        case .cloudBackup:
            return "ERROR: Failed to backup to your iCloud"
        case .restore:
            return "ERROR: Failed to restore"
        case .fileRestore:
            return "ERROR: Failed to restore from file"
        case .cloudRestore:
            return "ERROR: Failed to restore from your iCloud"
        case .none:
            break
        }
        return "ERROR"
    }

    private func getBackupOperationErrorMessage(_ operation: BackupOperation, _ message: String) -> String {
        switch operation {
        case .backup:
            return "Could to backup to the clipboard: \(message)"
        case .fileBackup:
            return "Could to backup to the file: \(message)"
        case .cloudBackup:
            return "Could to backup to your iCloud documents: \(message)"
        case .restore:
            return "Could to restore from the clipboard: \(message)"
        case .fileRestore:
            return "Could to restore from the file: \(message)"
        case .cloudRestore:
            return "Could to restore from your iCloud documents: \(message)"
        case .none:
            break
        }
        return message
    }

    private func addPage() {
        logger.verbose("Tapped to add page", context: "User")
        withAnimation {
            let newPage = Page(id: UUID(), name: "new page", hub: "")
            modelContext.insert(newPage)
            selectedPage = newPage
            logger.verbose("Added new page", context: "System")
        }
    }

    private func getFeatures(_ hub: String? = nil) -> Int {
        var total = 0
        for page in pages {
            if let hub {
                if page.hub.lowercased() == hub.lowercased() {
                    total += page.features!.count
                }
            } else {
                total += page.features!.count
            }
        }
        return total
    }

    private func getTotalFeatures(_ hub: String? = nil) -> Int {
        var total = 0
        for page in pages {
            if let hub {
                if page.hub.lowercased() == hub.lowercased() {
                    total += page.features!.count * page.count
                }
            } else {
                total += page.features!.count * page.count
            }
        }
        return total
    }

    private func getPages(_ hub: String? = nil) -> Int {
        var total = 0
        for page in pages {
            if let hub {
                if page.hub.lowercased() == hub.lowercased() {
                    total += page.features!.isEmpty ? 0 : 1
                }
            } else {
                total += page.features!.isEmpty ? 0 : 1
            }
        }
        return total
    }

    private func getTotalPages(_ hub: String? = nil) -> Int {
        var total = 0
        for page in pages {
            if let hub {
                if page.hub.lowercased() == hub.lowercased() {
                    total += page.features!.isEmpty ? 0 : page.count
                }
            } else {
                total += page.features!.isEmpty ? 0 : page.count
            }
        }
        return total
    }

    private func getMembership(_ hub: String) -> String {
        let features = getTotalFeatures(hub)
        let pages = getTotalPages(hub)

        if hub == "snap" {
            if features < 5 {
                return "Artist"
            }
            if features < 15 {
                return "Member"
            }
            if pages < 15 {
                return "VIP Member"
            }
            if pages < 35 {
                return "VIP Gold Member"
            }
            if pages < 55 {
                return "Platinum Member"
            }
            if pages < 80 {
                return "Elite Member"
            }
            return "Hall of Fame Member"
        }

        if hub == "click" {
            if features < 5 {
                return "Artist"
            }
            if features < 15 {
                return "Bronze member"
            }
            if features < 30 {
                return "Silver Member"
            }
            if features < 50 {
                return "Gold Member"
            }
            return "Platinum Member"
        }

        return "Artist"
    }

    private func hasMembershipLevels(_ hub: String) -> Bool {
        hub == "snap" || hub == "click"
    }

    private func getFeaturesForPage(_ lonePage: String? = nil) -> Int {
        var total = 0
        for page in pages {
            if page.name.lowercased() == lonePage?.lowercased() {
                total += page.features!.count
            }
        }
        return total
    }

    private func getTotalFeaturesForPage(_ lonePage: String? = nil) -> Int {
        var total = 0
        for page in pages {
            if page.name.lowercased() == lonePage?.lowercased() {
                total += page.features!.count * page.count
            }
        }
        return total
    }

    private func copyToClipboard(_ text: String) {
#if os(iOS)
        UIPasteboard.general.string = text
#else
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.writeObjects([text as NSString])
#endif
    }

    private func getStringForCount(_ count: Int, _ countLabel: String) -> String {
        if count == 1 {
            return "\(count) \(countLabel)"
        }
        return "\(count) \(countLabel)s"
    }

    private func getFeaturesSummary(_ hub: String? = nil) -> String {
        let featuresCount = getFeatures(hub)
        let totalFeaturesCount = getTotalFeatures(hub)
        if featuresCount != totalFeaturesCount && hub != nil {
            return "Total features: \(featuresCount) (counts as \(totalFeaturesCount))"
        }
        return "Total features: \(featuresCount)"
    }

    private func getFeaturesSummaryForPage(_ lonePage: String? = nil) -> String {
        let featuresCount = getFeaturesForPage(lonePage)
        let totalFeaturesCount = getTotalFeaturesForPage(lonePage)
        if featuresCount != totalFeaturesCount {
            return "Total features: \(featuresCount) (counts as \(totalFeaturesCount))"
        }
        return "Total features: \(featuresCount)"
    }

    private func getPagesSummary(_ hub: String? = nil) -> String {
        let pagesCount = getPages(hub)
        let totalPagesCount = getTotalPages(hub)
        if pagesCount != totalPagesCount && hub != nil {
            return "Total pages with features: \(pagesCount) (counts as \(totalPagesCount))"
        }
        return "Total pages with features: \(pagesCount)"
    }

    private func getMembershipSummary(_ hub: String) -> String {
        return "Membership level: \(getMembership(hub))"
    }

    private func generateReportForHub(_ hub: String) {
        logger.verbose("Tapped generate report", context: "User")
        var lines = [String]()
        lines.append("Report of features for \(hub.capitalized)")
        lines.append("-" * (23 + hub.count))
        lines.append("")
        lines.append(getFeaturesSummary(hub))
        lines.append("")
        lines.append(getPagesSummary(hub))
        if hasMembershipLevels(hub) {
            lines.append("")
            lines.append(getMembershipSummary(hub))
        }
        for page in pages.filter({ $0.hub.lowercased() == hub.lowercased() }).sorted(by: { left, right in
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
                return (left.features?.count ?? 0) > (right.features?.count ?? 0)
            }
            return left.name < right.name
        }) {
            if page.features!.count > 0 {
                lines.append("")
                if page.count != 1 {
                    lines.append("Page: \(page.hub.lowercased())_\(page.name.lowercased()) - \(getStringForCount(page.features!.count, "feature")) (counts as \(page.features!.count * page.count))")
                } else {
                    lines.append("Page: \(page.hub.lowercased())_\(page.name.lowercased()) - \(getStringForCount(page.features!.count, "feature"))")
                }
                for feature in page.features!.sorted(by: { $0.date > $1.date }) {
                    if hub.lowercased() == "snap" {
                        lines.append("    Feature: \(feature.date.formatted(date: .complete, time: .omitted))\(feature.raw ? " [RAW]" : "") - \(feature.notes)")
                    } else {
                        lines.append("    Feature: \(feature.date.formatted(date: .complete, time: .omitted)) - \(feature.notes)")
                    }
                }
            }
        }
        var text = ""
        for line in lines { text = text + line + "\n" }
        copyToClipboard(text)
        viewModel.showSuccessToast("Report generated!", "Copied the report of features to the clipboard")
        logger.verbose("Generated report", context: "System")
    }

    private func generateReportForPage(_ lonePage: String) {
        logger.verbose("Tapped generate report", context: "User")
        var lines = [String]()
        lines.append("Report of features for \(lonePage.lowercased())")
        lines.append("-" * (23 + lonePage.count))
        lines.append("")
        lines.append(getFeaturesSummaryForPage(lonePage))
        if let page = pages.first(where: { $0.name.lowercased() == lonePage.lowercased() }) {
            if page.features!.count > 0 {
                lines.append("")
                for feature in page.features!.sorted(by: { $0.date > $1.date }) {
                    lines.append("Feature: \(feature.date.formatted(date: .complete, time: .omitted)) - \(feature.notes)")
                }
            }
        }
        var text = ""
        for line in lines { text = text + line + "\n" }
        copyToClipboard(text)
        viewModel.showSuccessToast("Report generated!", "Copied the report of features to the clipboard")
        logger.verbose("Generated report", context: "System")
    }

    private func getOptionalHubAndName(_ page: Page) -> String {
        if page.hub.isEmpty || page.hub.lowercased() == page.name.lowercased() {
            return page.name.lowercased()
        }
        return "\(page.hub)_\(page.name)".lowercased()
    }

    private func backup() {
        logger.verbose("Tapped backup to clipboard", context: "User")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            var codablePages = [CodablePage]()
            codablePages.append(contentsOf: pages.sorted(by: { getOptionalHubAndName($0) < getOptionalHubAndName($1) }).map({ page in
                CodablePage(page)
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

    private func backupToFile() -> BackupDocument {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        var codablePages = [CodablePage]()
        codablePages.append(contentsOf: pages.sorted(by: { getOptionalHubAndName($0) < getOptionalHubAndName($1) }).map({ page in
            CodablePage(page)
        }))
        return BackupDocument(pages: codablePages)
    }

    private func backupToCloud() {
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
                codablePages.append(contentsOf: pages.sorted(by: { getOptionalHubAndName($0) < getOptionalHubAndName($1) }).map({ page in
                    CodablePage(page)
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
                        if iCloudActive {
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

    private func showCloudBackupErrorToast(_ message: String) {
        logger.error("Failed to backup to iCloud: \(message)", context: "System")
        debugPrint("iCloud backup failed: \(message)")
        exceptionError = message
        iCloudError = exceptionError
        iCloudActive = false
        backupOperation = .cloudBackup
        showingBackupRestoreErrorAlert.toggle()
    }

    private func restore() {
        logger.verbose("Tapped restore from clipboard", context: "User")
        do {
            let pasteBoard = NSPasteboard.general
            let json = pasteBoard.string(forType: .string) ?? ""
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let codablePages = try decoder.decode([CodablePage].self, from: json.data(using: .utf8)!)
            if codablePages.count != 0 {
                do {
                    try modelContext.transaction {
                        try modelContext.delete(model: Page.self)
                    }
                    let count = try modelContext.fetchCount(FetchDescriptor<Page>())
                    if count > 0 {
                        logger.error("Failed to delete all the existing records during restore, there were some records left", context: "System")
                        viewModel.showToast(
                            .error,
                            "Restore failed!",
                            "Could not remove all the existing records before doing the restore, the database is likely in invalid state")
                        return
                    }
                } catch {
                    logger.error("Failed to delete all the existing records during restore", context: "System")
                    debugPrint(error.localizedDescription)
                    viewModel.showToast(
                        .error,
                        "Restore failed!",
                        "Could not remove all the existing records before doing the restore (\(error.localizedDescription)), the database is likely in invalid state")
                    return
                }
                let pages = SchemaV3.collatePages(codablePages.map({ $0.toPage() }))
                for page in pages {
                    modelContext.insert(page)
                }
                try? modelContext.save()
                logger.verbose("Restored from clipboard", context: "System")
                let featureCount = getFeatures()
                let pageCount = getPages()
                viewModel.showSuccessToast("Restored!", "Restored the items from the clipboard, \(pageCount) pages and \(featureCount) features restored.")
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

    private func showRestoreErrorToast(_ message: String) {
        logger.error("Failed to restore from clipboard: \(message)", context: "System")
        debugPrint("iCloud restore failed: \(message)")
        exceptionError = message
        backupOperation = .restore
        showingBackupRestoreErrorAlert.toggle()
    }

    private func restoreFromFile(from fileUrl: URL) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: { @MainActor in
            logger.verbose("Tapped restore from file", context: "User")
            let gotAccess = fileUrl.startAccessingSecurityScopedResource()
            if !gotAccess {
                logger.error("Failed to access the file to restore", context: "System")
                viewModel.showToast(.error, "Could not access file", "Could not access the file to restore the features")
                return
            }
            do {
                let fileContents = FileManager.default.contents(atPath: fileUrl.path)
                if let json = fileContents {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let codablePages = try decoder.decode([CodablePage].self, from: json)
                    if codablePages.count != 0 {
                        do {
                            try modelContext.transaction {
                                try modelContext.delete(model: Page.self)
                            }
                            let count = try modelContext.fetchCount(FetchDescriptor<Page>())
                            if count > 0 {
                                logger.error("Failed to delete all the existing records during restore, there were some records left", context: "System")
                                fileUrl.stopAccessingSecurityScopedResource()
                                viewModel.showToast(
                                    .error,
                                    "Restore failed!",
                                    "Could not remove all the existing records before doing the restore (remaining items), the database is likely in invalid state")
                                return
                            }
                        } catch {
                            logger.error("Failed to delete all the existing records during restore", context: "System")
                            debugPrint(error.localizedDescription)
                            fileUrl.stopAccessingSecurityScopedResource()
                            viewModel.showToast(
                                .error,
                                "Restore failed!",
                                "Could not remove all the existing records before doing the restore (\(error.localizedDescription)), the database is likely in invalid state")
                            return
                        }
                        let pages = SchemaV3.collatePages(codablePages.map({ $0.toPage() }))
                        for page in pages {
                            modelContext.insert(page)
                        }
                        try? modelContext.save()
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: { @MainActor in
                            let featureCount = getFeatures()
                            let pageCount = getPages()
                            viewModel.showSuccessToast("Restored from file!", "Restored the items from the file, \(pageCount) pages and \(featureCount) features restored.")
                            logger.verbose("Restored from file", context: "System")
                        })
                    } else {
                        showFileRestoreErrorToast("No pages found in the backup")
                    }
                } else {
                    showFileRestoreErrorToast("No pages loaded from the backup")
                }
            } catch let DecodingError.dataCorrupted(context) {
                showFileRestoreErrorToast(context.debugDescription)
            } catch let DecodingError.keyNotFound(key, context) {
                showFileRestoreErrorToast("Key '\(key)' not found:" + context.debugDescription)
            } catch let DecodingError.valueNotFound(value, context) {
                showFileRestoreErrorToast("Value '\(value)' not found:" + context.debugDescription)
            } catch let DecodingError.typeMismatch(type, context) {
                showFileRestoreErrorToast("Type '\(type)' mismatch:" + context.debugDescription)
            } catch {
                showFileRestoreErrorToast(error.localizedDescription)
            }
            fileUrl.stopAccessingSecurityScopedResource()
        })
    }

    private func showFileRestoreErrorToast(_ message: String) {
        logger.error("Failed to restore from file: \(message)", context: "System")
        debugPrint("File restore failed: \(message)")
        exceptionError = message
        iCloudError = exceptionError
        backupOperation = .fileRestore
        showingBackupRestoreErrorAlert.toggle()
    }

    private func restoreFromCloud() {
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
                                        try modelContext.transaction {
                                            try modelContext.delete(model: Page.self)
                                        }
                                        let count = try modelContext.fetchCount(FetchDescriptor<Page>())
                                        if count > 0 {
                                            logger.error("Failed to delete all the existing records during restore, there were some records left", context: "System")
                                            viewModel.showToast(
                                                .error,
                                                "Restore failed!",
                                                "Could not remove all the existing records before doing the restore (remaining items), the database is likely in invalid state")
                                            return
                                        }
                                    } catch {
                                        logger.error("Failed to delete all the existing records during restore", context: "System")
                                        debugPrint(error.localizedDescription)
                                        viewModel.showToast(
                                            .error,
                                            "Restore failed!",
                                            "Could not remove all the existing records before doing the restore (\(error.localizedDescription)), the database is likely in invalid state")
                                        return
                                    }
                                    let pages = SchemaV3.collatePages(codablePages.map({ $0.toPage() }))
                                    for page in pages {
                                        modelContext.insert(page)
                                    }
                                    try? modelContext.save()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: { @MainActor in
                                        let featureCount = getFeatures()
                                        let pageCount = getPages()
                                        viewModel.showSuccessToast("Restored from iCloud!", "Restored the items from your iCloud, \(pageCount) pages and \(featureCount) features restored.")
                                        logger.verbose("Restored from iCloud", context: "System")
                                    })
                                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: { @MainActor in
                                        if iCloudActive {
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

    private func showCloudRestoreErrorToast(_ message: String) {
        logger.error("Failed to restore from iCloud document: \(message)", context: "System")
        debugPrint("iCloud restore failed: \(message)")
        exceptionError = message
        iCloudError = exceptionError
        iCloudActive = false
        backupOperation = .cloudRestore
        showingBackupRestoreErrorAlert.toggle()
    }

    private func populateDefaultPages() {
        do {
            try modelContext.delete(model: Page.self)
            let count = try modelContext.fetchCount(FetchDescriptor<Page>())
            if count > 0 {
                logger.error("Failed to delete all the existing records during populate, there were some records left", context: "System")
                viewModel.showToast(
                    .error,
                    "Failed to reset the store!",
                    "Could not remove all the existing records before doing the populate (remaining items), the database is likely in invalid state")
                return
            }
        } catch {
            logger.error("Failed to reset the store: \(error.localizedDescription)", context: "System")
            viewModel.showToast(
                .error,
                "Failed to reset the store!",
                "Could not remove all the existing records before doing the populate, the database is likely in invalid state")
            return
        }

        // Add regular snap pages.
        let singleFeaturePagesForSnap = [
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
        for pageName in singleFeaturePagesForSnap {
            modelContext.insert(Page(id: UUID(), name: pageName, hub: "snap"))
        }

        // Add the multi-count features.
        modelContext.insert(Page(id: UUID(), name: "papanoel", hub: "snap", count: 3))
        for pageName in singleFeaturePagesForSnap {
            modelContext.insert(Page(id: UUID(), name: pageName, hub: "snap"))
        }

        // Add regular click pages.
        let singleFeaturePagesForClick = [
            "astro",
            "dogs",
            "machines",
        ]
        for pageName in singleFeaturePagesForClick {
            modelContext.insert(Page(id: UUID(), name: pageName, hub: "click"))
        }

        // Add regular podium pages.
        let singleFeaturePagesForPodium = [
            "podium",
            "macro",
            "mono",
            "night",
            "portraits",
            "street",
            "wildlife",
        ]
        for pageName in singleFeaturePagesForPodium {
            modelContext.insert(Page(id: UUID(), name: pageName, hub: "podium"))
        }

        try? modelContext.save()
        logger.verbose("Populated the defaults", context: "System")
    }
}
