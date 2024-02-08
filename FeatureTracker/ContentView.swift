//
//  ContentView.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query var pages: [Page]
    @State private var path = [Page]()
    @State private var sortOrder = SortDescriptor(\Page.name)
    @State private var showingRepopulateAlert = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                HStack(alignment: .center) {
                    Text("Total features: \(getTotalFeatures())")
                    Spacer()
                        .frame(width: 8)
                    Text("|")
                    Spacer()
                        .frame(width: 8)
                    Text("Total pages: \(getTotalPages())")
                    Text("|")
                    Spacer()
                        .frame(width: 8)
                    Text("Membership: \(getMembership())")
                    Spacer()
                }
                .padding()
                PageListing(sort: sortOrder)
                    .navigationTitle("Feature Tracker")
                    .navigationDestination(for: Page.self, destination: PageEditor.init)
                    .toolbar {
                        Button("Populate defaults", action: { showingRepopulateAlert.toggle() })
                        Button("Add page", systemImage: "plus", action: addPage)
                        Menu("Sort", systemImage: "arrow.up.arrow.down") {
                            Picker("Sort", selection: $sortOrder) {
                                Text("Name").tag(SortDescriptor(\Page.name))
                                Text("Count").tag(SortDescriptor(\Page.count))
                                //Text("Features").tag(SortDescriptor(\Page.features.count)) // TODO crashes?
                            }
                            .pickerStyle(.inline)
                        }
                    }
            }
        }
        .alert(
            "Are you sure?",
            isPresented: $showingRepopulateAlert,
            actions: {
                Button(action: {
                    showingRepopulateAlert.toggle()
                }){
                    Text("No")
                        .background(Color.blue)
                }
                Button(action: {
                    populateDefaultPages()
                }) {
                    Text("Yes")
                        .background(Color.red)
                }
            },
            message: { Text("This will remove all features and custom pages and cannot be undone.") }
        )
        .dialogIcon(nil)
    }
    
    func getTotalFeatures() -> Int {
        var total = 0
        for page in pages {
            total += page.features.count * page.count
        }
        return total
    }
    
    func getTotalPages() -> Int {
        var total = 0
        for page in pages {
            total += page.features.isEmpty ? 0 : page.count
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
    
    func populateDefaultPages() -> Void {
        do {
            try modelContext.delete(model: Page.self)
        } catch {
            // do nothing
        }
        let singleFeaturePages = [
            "abandoned",
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
            "default",
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
        modelContext.insert(Page(name: "papenoel", count: 3))
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
