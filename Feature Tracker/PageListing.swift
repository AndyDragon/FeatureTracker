//
//  PageListing.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import SwiftData
import SwiftUI

enum PageSorting: Int, Codable, CaseIterable {
    case none,
         name,
         count,
         features
}

struct PageListing: View {
    @Environment(\.modelContext) var modelContext
    @Query var pages: [Page]
    var sorting = PageSorting.name
    @Binding var selectedPage: Page?
    @Binding var selectedFeature: Feature?
    @State var searchTerm: String = ""
    
    private var filteredPages: [Page] {
        if searchTerm.isEmpty {
            return pages
        } else {
            return pages.filter( { $0.name.localizedStandardContains(searchTerm) || $0.hub.localizedStandardContains(searchTerm) })
        }
    }

    private func pageFullName(_ page: Page) -> String {
        if page.hub.isEmpty || page.hub.lowercased() == page.name.lowercased() {
            return page.name.lowercased()
        }
        return (page.hub + "_" + page.name).lowercased()
    }

    private var sortedPages: [Page] {
        filteredPages.sorted(by: { left, right in
            let leftPageName = pageFullName(left)
            let rightPageName = pageFullName(right)
            if sorting == .name {
                return leftPageName < rightPageName
            } else if sorting == .count {
                if left.count == right.count {
                    return leftPageName < rightPageName
                }
                return left.count > right.count
            } else if sorting == .features {
                if left.features?.count == right.features?.count {
                    return leftPageName < rightPageName
                }
                return (left.features?.count ?? 0) > (right.features?.count ?? 0);
            }
            return leftPageName < rightPageName
        })
    }

    var body: some View {
        List(selection: $selectedPage) {
            ForEach(sortedPages, id: \.self) { page in
                HStack {
                    HStack (alignment: .center, spacing: 0) {
                        Image(systemName: page.isChallenge ? "calendar.badge.checkmark" : "book.pages.fill")
                            .frame(width: 24, height: 24)
                        Text("\((!page.hub.isEmpty && page.hub != page.name) ? (page.hub + "_") : "")\(page.name)".lowercased())
                            .font(.headline)
                            .foregroundColor(page.features!.count > 0 ? .blue : Color(.textColor))
                            .brightness(page.features!.count > 0 ? 0.3 : 0)
                        if page.count > 1 {
                            Text("(\(page.count))")
                                .font(.subheadline)
                                .padding([.leading], 8)
                                .foregroundColor(.gray)
                                .help("Counts as \(page.count)")
                        }
                    }
                    Spacer()
                    Text("\(getStringForCount(page.features!.count, "feature"))")
                        .font(.headline)
                        .foregroundColor(page.features!.count > 0 ? .blue : Color(.textColor))
                        .brightness(page.features!.count > 0 ? 0.3 : 0)
                        .frame(alignment: .top)
                }
                .onTapGesture {
                    selectedFeature = nil
                    withAnimation {
                        selectedPage = page
                    }
                }
                .testBackground()
            }
        }
        .searchable(text: $searchTerm, placement: .sidebar, prompt: "Search for page")
    }

    private func getStringForCount(_ count: Int, _ countLabel: String) -> String {
        if count == 1 {
            return "\(count) \(countLabel)"
        }
        return "\(count) \(countLabel)s"
    }
}
