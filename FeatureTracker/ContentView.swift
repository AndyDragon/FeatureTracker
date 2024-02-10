//
//  ContentView.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-07.
//

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
    @State private var showingRepopulateAlert = false
    @State private var showingCopiedToClipboardAlert = false
    @State private var clipboardName = ""
    @State private var exceptionError = ""
    @State private var backupOperation = BackupOperation.none
    @State private var showingBackupRestoreErrorAlert = false
    @AppStorage("pageSorting", store: .standard) private var pageSorting = PageSorting.name

    var body: some View {
        NavigationStack(path: $path) {
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
                PageListing(sorting: pageSorting)
                    .navigationTitle("Feature Tracker")
                    .navigationDestination(for: Page.self, destination: PageEditor.init)
                    .toolbar {
                        Button("Populate defaults", action: { showingRepopulateAlert.toggle() })
                        Button("Generate report", systemImage: "menucard", action: generateReport)
                        Button("Add page", systemImage: "plus", action: addPage)
                        Menu("Sort", systemImage: "arrow.up.arrow.down") {
                            Picker("Sort", selection: $pageSorting) {
                                Text("Name").tag(PageSorting.name)
                                Text("Count").tag(PageSorting.count)
                                Text("Features").tag(PageSorting.features)
                            }
                            .pickerStyle(.inline)
                        }
                        Menu("JSON", systemImage: "tray") {
                            Button("Backup", systemImage: "tray.and.arrow.down", action: backup)
                            Button("Restore", systemImage: "tray.and.arrow.up", action: restore)
                        }
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
            "Copied to clipboard",
            isPresented: $showingCopiedToClipboardAlert,
            actions: {
                Button(action: {
                    showingCopiedToClipboardAlert.toggle()
                }) {
                    Text("OK")
                }
            },
            message: {
                Text("Copied the \(clipboardName) to the clipboard.")
            }
        )
        .alert(
            backupOperation == .backup
            ? "ERROR: Failed to backup"
            : "ERROR: Failed to restore",
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
        clipboardName = "report"
        showingCopiedToClipboardAlert.toggle()
    }

    func backup() -> Void {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            let json = try encoder.encode(pages.sorted { $0.name < $1.name })
            copyToClipboard(String(decoding: json, as: UTF8.self))
            clipboardName = "backup"
            showingCopiedToClipboardAlert.toggle()
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
        let page = Page()
        modelContext.insert(page)
        path = [page]
    }
}

#Preview {
    ContentView()
}
