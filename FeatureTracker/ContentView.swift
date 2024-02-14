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

enum BackupOperation: Int, Codable, CaseIterable {
    case none,
         backup,
         restore
}

struct ContentView: View {
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
    @State private var showToast = false
    @State private var deleteAlertText = ""
    @State private var deleteAlertAction: (() -> Void)? = nil
    @State private var showDeleteAlert = false
    @AppStorage("pageSorting", store: .standard) private var pageSorting = PageSorting.name
    @ObservedObject private var syncMonitor = SyncMonitor.shared

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                let featuresCount = getFeatures()
                let totalFeaturesCount = getTotalFeatures()
                if (featuresCount != totalFeaturesCount) {
                    Text("Total features: \(featuresCount) (counts as \(totalFeaturesCount))")
                } else {
                    Text("Total features: \(featuresCount)")
                    
                }
                Spacer()
                    .frame(width: 8)
                Text("|")
                Spacer()
                    .frame(width: 8)
                let pagesCount = getPages()
                let totalPagesCount = getTotalPages()
                if pagesCount != totalPagesCount {
                    Text("Total pages: \(pagesCount) (counts as \(totalPagesCount))")
                } else {
                    Text("Total pages: \(pagesCount)")
                }
                Text("|")
                Spacer()
                    .frame(width: 8)
                Text("Membership: \(getMembership())")
                Spacer()
            }
            .padding()
            .toast(isPresenting: $showToast, duration: toastDuration, tapToDismiss: true, alert: {
                AlertToast(
                    displayMode: .hud,
                    type: toastType,
                    title: toastText,
                    subTitle: toastSubTitle)
            })
            NavigationSplitView {
                PageListing(sorting: pageSorting, selectedPage: $selectedPage, selectedFeature: $selectedFeature)
                    .navigationTitle("Feature Tracker")
                    .listStyle(.sidebar)
                    .navigationSplitViewColumnWidth(min: 280, ideal: 320)
                    .toolbar {
                        Button("Add page", systemImage: "plus", action: addPage)
                        Menu("Sort", systemImage: "arrow.up.arrow.down") {
                            Picker("Sort pages by", selection: $pageSorting) {
                                Text("Name").tag(PageSorting.name)
                                Text("Count").tag(PageSorting.count)
                                Text("Features").tag(PageSorting.features)
                            }
                            .pickerStyle(.inline)
                        }
                    }
            } detail: {
                VStack {
                    if let page = selectedPage {
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
                        })
                    } else {
                        HStack {
                            Spacer()
                            Text("Select page from the list to edit")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
                .toolbar {
                    Button("Populate defaults", action: { showingRepopulateAlert.toggle() })
                    Button("Generate report", systemImage: "menucard", action: generateReport)
                    Menu("JSON", systemImage: "tray") {
                        Button("Backup to Clipboard", systemImage: "tray.and.arrow.down", action: backup)
                        Button("Restore from Clipboard", systemImage: "tray.and.arrow.up", action: restore)
                    }
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
                backupOperation == .backup ? "ERROR: Failed to backup" : "ERROR: Failed to restore",
                isPresented: $showingBackupRestoreErrorAlert,
                actions: {
                    Button(action: {
                        showingBackupRestoreErrorAlert.toggle()
                    }) {
                        Text("OK")
                    }
                },
                message: {
                    Text(backupOperation == .backup
                         ? "Could to backup to the clipboard: \(exceptionError)"
                         : "Could to restore from the clipboard: \(exceptionError)")
                    .accentColor(.red)
                }
            )
            HStack {
                Image(systemName: syncMonitor.syncStateSummary.symbolName)
                    .foregroundColor(syncMonitor.syncStateSummary.symbolColor)
                    .help(syncMonitor.syncStateSummary.description)
                if showSyncAccountStatus {
                    if case .accountNotAvailable = syncMonitor.syncStateSummary {
                        Text("Not logged into iCloud account, changes will not be synced to iCloud storage")
                    }
                }
                Spacer()
            }
            .padding([.top], 2)
            .padding([.bottom, .leading], 12)
            .task {
                do {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    showSyncAccountStatus = true
                } catch {}
            }
        }
    }
    
    func showToast(_ text: String, _ subTitle: String, duration: Double = 3.0) {
        toastType = .complete(.blue)
        toastText = text
        toastSubTitle = subTitle
        toastDuration = duration
        showToast.toggle()
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

    func generateReport() -> Void {
        var lines = [String]()
        lines.append("Report of features")
        lines.append("------------------")
        lines.append("")
        let featuresCount = getFeatures()
        let totalFeaturesCount = getTotalFeatures()
        if (featuresCount != totalFeaturesCount) {
            lines.append("Total features: \(featuresCount) (counts as \(totalFeaturesCount))")
        } else {
            lines.append("Total features: \(featuresCount)")
        }
        lines.append("")
        let pagesCount = getPages()
        let totalPagesCount = getTotalPages()
        if (pagesCount != totalPagesCount) {
            lines.append("Total pages with features: \(pagesCount) (counts as \(totalPagesCount))")
        } else {
            lines.append("Total pages with features: \(pagesCount)")
        }
        lines.append("")
        lines.append("Membership level: \(getMembership())")
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
                for feature in page.features!.sorted(by: { $0.date < $1.date }) {
                    lines.append("\tFeature: \(feature.date.formatted(date: .abbreviated, time: .omitted)) on \(feature.raw ? "RAW" : "Snap"):")
                    lines.append("\t\t\(feature.notes)")
                }
            }
        }
        var text = ""
        for line in lines { text = text + line + "\n" }
        copyToClipboard(text)
        showToast("Report generated!", "Copied the report of features to the clipboard")
    }

    func backup() -> Void {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            let json = try encoder.encode(pages.sorted { $0.name < $1.name })
            copyToClipboard(String(decoding: json, as: UTF8.self))
            showToast("Backed up!", "Copied a backup of the features to the clipboard")
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
            let loadedPages = try JSONDecoder().decode([Page].self, from: json.data(using: .utf8)!)
            if loadedPages.count != 0 {
                do {
                    try modelContext.delete(model: Page.self)
                } catch {
                    // do nothing
                }
                for page in loadedPages {
                    modelContext.insert(page)
                }
                showToast("Restored!", "Restored the items from the clipboard")
            }
        } catch let DecodingError.dataCorrupted(context) {
            exceptionError = context.debugDescription
            backupOperation = .restore
            showingBackupRestoreErrorAlert.toggle()
        } catch let DecodingError.keyNotFound(key, context) {
            exceptionError = "Key '\(key)' not found:" + context.debugDescription
            backupOperation = .restore
            showingBackupRestoreErrorAlert.toggle()
        } catch let DecodingError.valueNotFound(value, context) {
            exceptionError = "Value '\(value)' not found:" + context.debugDescription
            backupOperation = .restore
            showingBackupRestoreErrorAlert.toggle()
        } catch let DecodingError.typeMismatch(type, context) {
            exceptionError = "Type '\(type)' mismatch:" + context.debugDescription
            backupOperation = .restore
            showingBackupRestoreErrorAlert.toggle()
        } catch {
            exceptionError = error.localizedDescription
            backupOperation = .restore
            showingBackupRestoreErrorAlert.toggle()
        }
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
            modelContext.insert(Page(name: pageName))
        }
        // Add the multi-count features.
        modelContext.insert(Page(name: "papanoel", count: 3))
    }

    func addPage() -> Void {
        withAnimation {
            let newPage = Page(name: "new page")
            modelContext.insert(newPage)
            selectedPage = newPage
        }
    }
}

#Preview {
    ContentView()
}
