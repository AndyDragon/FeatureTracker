//
//  ContentView.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import AlertToast
import CloudKitSyncMonitor
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.modelContext) var modelContext
    @Query var pages: [Page]
    @State private var path = [Page]()
    @State private var selectedPage: Page?
    @State private var selectedFeature: Feature?
    @State private var showingRepopulateAlert = false
    @State private var exceptionError = ""
    @State private var backupOperation = BackupOperation.none
    @State private var showingBackupRestoreErrorAlert = false
    @State private var showSyncAccountStatus = false
    @State private var toastDuration = 3.0
    @State private var toastType: AlertToast.AlertType = .regular
    @State private var toastText = ""
    @State private var toastSubTitle = ""
    @State private var toastCompleteAction: () -> Void = {}
    @State private var isShowingToast = false
    @State private var deleteAlertText = ""
    @State private var deleteAlertAction: (() -> Void)? = nil
    @State private var showDeleteAlert = false
    @State private var isShowingDuplicatePages = false;
    @State private var selectedDuplicatePage = UUID();
    private var duplicatePages = DuplicatePages();
    @AppStorage("pageSorting", store: .standard) private var pageSorting = PageSorting.name
    @ObservedObject private var syncMonitor = SyncMonitor.shared
    var appState: VersionCheckAppState
    private var isAnyToastShowing: Bool {
        isShowingToast || appState.isShowingVersionAvailableToast.wrappedValue || appState.isShowingVersionRequiredToast.wrappedValue
    }

    init(_ appState: VersionCheckAppState) {
        self.appState = appState
    }

    var body: some View {
        NavigationSplitView {
            ZStack {
                VStack {
                    PageListing(sorting: pageSorting, selectedPage: $selectedPage, selectedFeature: $selectedFeature)
                        .listStyle(.sidebar)
                        .onDeleteCommand {
                            if let page = selectedPage {
                                deleteAlertText = "Are you sure you want to delete this page?"
                                deleteAlertAction = {
                                    selectedFeature = nil
                                    selectedPage = nil
                                    modelContext.delete(page)
                                    showToast("Deleted page!", "Removed the page and all the features")
                                }
                                showDeleteAlert.toggle()
                            }
                        }
                        .navigationSplitViewColumnWidth(min: 280, ideal: 320)
                        .toolbar {
                            Button("Add page", systemImage: "plus", action: addPage)
                                .disabled(isAnyToastShowing)
                            Menu("Sort", systemImage: "arrow.up.arrow.down") {
                                Picker("Sort pages by", selection: $pageSorting) {
                                    Text("Name").tag(PageSorting.name)
                                    Text("Count").tag(PageSorting.count)
                                    Text("Features").tag(PageSorting.features)
                                }
                                .pickerStyle(.inline)
                            }
                            .disabled(isAnyToastShowing)
                        }
                    if CloudKitConfiguration.Enabled {
                        HStack {
                            Image(systemName: syncMonitor.syncStateSummary.symbolName)
                                .foregroundColor(syncMonitor.syncStateSummary.symbolColor)
                                .help(syncMonitor.syncError
                                      ? (syncMonitor.syncStateSummary.description + " " + (syncMonitor.lastError?.localizedDescription ?? "unknown"))
                                      : syncMonitor.syncStateSummary.description)
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
                    }
                }
                ToastDismissShield(
                    isAnyToastShowing: isAnyToastShowing,
                    isShowingToast: $isShowingToast,
                    isShowingVersionAvailableToast: appState.isShowingVersionAvailableToast)
            }
            .blur(radius: isAnyToastShowing ? 4 : 0)
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
                            deleteAlertText = "Are you sure you want to delete this page?"
                            deleteAlertAction = {
                                selectedFeature = nil
                                selectedPage = nil
                                modelContext.delete(page)
                                showToast("Deleted page!", "Removed the page and all the features", duration: 15.0)
                            }
                            showDeleteAlert.toggle()
                        }, onDeleteFeature: { feature in
                            deleteAlertText = "Are you sure you want to delete this feature?"
                            deleteAlertAction = {
                                selectedFeature = nil
                                page.features!.remove(element: feature)
                                showToast("Deleted feature!", "Removed the feature", duration: 15.0)
                            }
                            showDeleteAlert.toggle()
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
                ToastDismissShield(
                    isAnyToastShowing: isAnyToastShowing,
                    isShowingToast: $isShowingToast,
                    isShowingVersionAvailableToast: appState.isShowingVersionAvailableToast)
            }
            .blur(radius: isAnyToastShowing ? 4 : 0)
            .toolbar {
                Button("Populate defaults", action: { showingRepopulateAlert.toggle() })
                    .disabled(isAnyToastShowing)
                Button("Generate report", systemImage: "menucard", action: generateReport)
                    .disabled(isAnyToastShowing)
                Button("Validate data", systemImage: "checkmark.rectangle.stack", action: validateData)
                    .disabled(isAnyToastShowing)
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
                        Button(action: restore) {
                            Label("Clipboard", systemImage: "tray.and.arrow.up")
                        }
                        Button(action: restoreFromCloud) {
                            Label("iCloud Documents", systemImage: "icloud.and.arrow.down")
                        }
                    }
                }
                .disabled(isAnyToastShowing)
            }
        }
        .alert(
            "Are you sure?",
            isPresented: $showingRepopulateAlert,
            actions: {
                Button(role: .destructive, action: {
                    populateDefaultPages()
                }) {
                    Text("Yes")
                }
            },
            message: {
                Text("This will remove all features and custom pages and cannot be undone.")
            }
        )
        .alert(
            "Delete confirmation",
            isPresented: $showDeleteAlert,
            actions: {
                Button(role: .destructive, action: deleteAlertAction ?? { }) {
                    Text("Yes")
                }
            },
            message: {
                Text(deleteAlertText)
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
        .sheet(
            isPresented: $isShowingDuplicatePages) {
                VStack {
                    Text("Duplicate page(s) found '\(duplicatePages.firstPageName)', which one should be kept:")
                    List {
                        ForEach(duplicatePages.duplicateList(pageName: duplicatePages.firstPageName)) { page in
                            ZStack {
                                Rectangle()
                                    .background(Color.gray)
                                    .opacity(0.2)
                                    .cornerRadius(4)
                                VStack(alignment: .leading) {
                                    HStack(alignment: .bottom) {
                                        Text("Name: '\(page.name)'")
                                        Spacer()
                                        Button("Keep", action: {
                                            deDuplicatePages(page: page)
                                        })
                                    }
                                    Text("ID: \(page.id)   |   Count: \(page.count)   |   Features: \(page.features!.count)")
                                }
                                .padding(8)
                                .frame(width: 600, alignment: .leading)
                                .tag(page.id)
                            }
                        }
                        .listStyle(.bordered)
                    }
                    .frame(width: 640, height: 320)
                    HStack(spacing: 12) {
                        Button(action: {
                            deDuplicateAllPages()
                        }, label: {
                            Text("Remove all duplicates")
                                .padding([.top, .bottom], 10)
                                .padding([.leading, .trailing], 20)
                        })
                        Button(action: {
                            skipDuplicationPages(pageName: duplicatePages.firstPageName)
                        }, label: {
                            Text("Keep all")
                                .padding([.top, .bottom], 10)
                                .padding([.leading, .trailing], 20)
                        })
                    }
                    .frame(alignment: .center)
                }
                .padding(40)
                .presentationDetents([.medium, .large])
            }
        .toast(
            isPresenting: $isShowingToast,
            duration: toastDuration,
            tapToDismiss: true,
            offsetY: 32,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: toastType,
                    title: toastText,
                    subTitle: toastSubTitle)
            },
            completion: toastCompleteAction)
        .toast(
            isPresenting: appState.isShowingVersionAvailableToast,
            duration: 10,
            tapToDismiss: true,
            offsetY: 32,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("exclamationmark.triangle.fill", .yellow),
                    title: "New version available",
                    subTitle: getVersionSubTitle())
            },
            onTap: {
                if let url = URL(string: appState.versionCheckToast.wrappedValue.linkToCurrentVersion) {
                    openURL(url)
                }
            },
            completion: {
                appState.resetCheckingForUpdates()
            })
        .toast(
            isPresenting: appState.isShowingVersionRequiredToast,
            duration: 0,
            tapToDismiss: true,
            offsetY: 32,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("xmark.octagon.fill", .red),
                    title: "New version required",
                    subTitle: getVersionSubTitle())
            },
            onTap: {
                if let url = URL(string: appState.versionCheckToast.wrappedValue.linkToCurrentVersion) {
                    openURL(url)
                    NSApplication.shared.terminate(nil)
                }
            },
            completion: {
                appState.resetCheckingForUpdates()
            })
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
    
    func getVersionSubTitle() -> String {
        if appState.isShowingVersionAvailableToast.wrappedValue {
            return "You are using v\(appState.versionCheckToast.wrappedValue.appVersion) " +
            "and v\(appState.versionCheckToast.wrappedValue.currentVersion) is available" +
            "\(appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty ? "" : ", click here to open your browser") " +
            "(this will go away in 10 seconds)"
        } else if appState.isShowingVersionRequiredToast.wrappedValue {
            return "You are using v\(appState.versionCheckToast.wrappedValue.appVersion) " +
            "and v\(appState.versionCheckToast.wrappedValue.currentVersion) is required" +
            "\(appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty ? "" : ", click here to open your browser") " +
            "or ⌘ + Q to Quit"
        }
        return ""
    }
    
    func showToast(_ text: String, _ subTitle: String, duration: Double = 2, toastComplete: @escaping () -> Void = {}) {
        withAnimation {
            toastType = .complete(.blue)
            toastText = text
            toastSubTitle = subTitle
            toastDuration = duration
            toastCompleteAction = toastComplete
            isShowingToast.toggle()
        }
    }

    func addPage() -> Void {
        withAnimation {
            let newPage = Page(id: UUID(), name: "new page")
            modelContext.insert(newPage)
            selectedPage = newPage
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
        showToast("Report generated!", "Copied the report of features to the clipboard")
    }
    
    func validateData() -> Void {
        duplicatePages.clear()
        var pagesChecked = [String : Page]()
        pages.forEach { page in
            if let firstPage = pagesChecked[page.name] {
                var duplicateList = [Page]();
                if !duplicatePages.hasPage(pageName: page.name) {
                    duplicateList.append(firstPage)
                }
                duplicateList.append(page)
                duplicatePages.setDuplicateList(pageName: page.name, duplicateList: duplicateList)
            }
            pagesChecked[page.name] = page
        }
        if !duplicatePages.isEmpty {
            print(duplicatePages)
            print(duplicatePages.firstPageName)
            isShowingDuplicatePages = true
        } else {
            showToast("Validation complete", "No duplicate pages")
        }
    }

    func deDuplicatePages(page: Page) -> Void {
        selectedFeature = nil
        selectedPage = nil
        var pagesDeleted = 0
        duplicatePages.duplicateList(pageName: page.name).forEach { duplicatePage in
            if duplicatePage.id != page.id {
                modelContext.delete(duplicatePage)
                pagesDeleted += 1
            }
        }
        isShowingDuplicatePages = false
        let deletedPageCount = getStringForCount(pagesDeleted, "page");
        duplicatePages.removeDuplicateList(pageName: page.name)
        showToast("Deleted duplicate pages!", "Removed \(deletedPageCount) and all the features", duration: 15.0) {
            if !duplicatePages.isEmpty {
                isShowingDuplicatePages = true
            }
        }
    }
    
    func deDuplicateAllPages() -> Void {
        selectedFeature = nil
        selectedPage = nil
        var pagesDeleted = 0
        while !duplicatePages.isEmpty {
            let duplicateList = duplicatePages.duplicateList(pageName: duplicatePages.firstPageName)
            let page = duplicateList[0]
            duplicateList.forEach { duplicatePage in
                if duplicatePage.id != page.id {
                    modelContext.delete(duplicatePage)
                    pagesDeleted += 1
                }
            }
            duplicatePages.removeDuplicateList(pageName: page.name)
        }
        isShowingDuplicatePages = false
        let deletedPageCount = getStringForCount(pagesDeleted, "page");
        showToast("Deleted all duplicate pages!", "Removed \(deletedPageCount) and all the features", duration: 15.0) {
            if !duplicatePages.isEmpty {
                isShowingDuplicatePages = true
            }
        }
    }
    
    func skipDuplicationPages(pageName: String) -> Void {
        isShowingDuplicatePages = false
        duplicatePages.removeDuplicateList(pageName: pageName)
        if !duplicatePages.isEmpty {
            isShowingDuplicatePages = true
        }
    }

    func backup() -> Void {
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
            showToast("Backed up!", "Copied a backup of the pages and features to the clipboard")
        } catch {
            exceptionError = error.localizedDescription
            backupOperation = .backup
            showingBackupRestoreErrorAlert.toggle()
        }
    }

    func backupToCloud() -> Void {
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
                
                showToast("Backed up to iCloud!", "Stored a backup of the pages and features to your iCloud documents")
            }
        } catch {
            exceptionError = error.localizedDescription
            backupOperation = .backup
            showingBackupRestoreErrorAlert.toggle()
        }
    }

    func restore() -> Void {
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
                    debugPrint(error.localizedDescription)
                }
                for codablePage in codablePages {
                    modelContext.insert(codablePage.toPage())
                }
                showToast("Restored!", "Restored the items from the clipboard", duration: 6)
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
        debugPrint("iCloud restore failed: \(message)")
        exceptionError = message
        backupOperation = .restore
        showingBackupRestoreErrorAlert.toggle()
    }
    
    func restoreFromCloud() -> Void {
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
                                    try modelContext.delete(model: Page.self)
                                } catch {
                                    // do nothing
                                    debugPrint(error.localizedDescription)
                                }
                                for codablePage in codablePages {
                                    modelContext.insert(codablePage.toPage())
                                }
                                showToast("Restored from iCloud!", "Restored the items from your iCloud", duration: 6)
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
    }
                                
    func showCloudRestoreErrorToast(_ message: String) {
        debugPrint("iCloud restore failed: \(message)")
        exceptionError = message
        backupOperation = .cloudRestore
        showingBackupRestoreErrorAlert.toggle()
    }

    func populateDefaultPages() -> Void {
        do {
            try modelContext.delete(model: Page.self)
        } catch {
            // do nothing
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
            "country",
            "cuteness",
            "depthoffield",
            "drone",
            "drops",
            "edit",
            "europe",
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
    }
}
