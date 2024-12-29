//
//  PageListing.swift
//  FeatureTracker
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
            return pages.filter( { $0.name.localizedStandardContains(searchTerm) })
        }
    }
    
    private var sortedPages: [Page] {
        filteredPages.sorted(by: { left, right in
            if sorting == .name {
                return left.name < right.name
            } else if sorting == .count {
                if left.count == right.count {
                    return left.name < right.name
                }
                return left.count > right.count
            } else if sorting == .features {
                if left.features?.count == right.features?.count {
                    return left.name < right.name
                }
                return (left.features?.count ?? 0) > (right.features?.count ?? 0);
            }
            return left.name < right.name
        })
    }

    var body: some View {
        List(selection: $selectedPage) {
            ForEach(sortedPages, id: \.self) { page in
                HStack {
                    HStack (alignment: .center, spacing: 0) {
                        Image(systemName: page.isChallenge ? "calendar.badge.checkmark" : "book.pages.fill")
                            .frame(width: 24, height: 24)
                        Text(page.name.uppercased())
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
