//
//  PageListing.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import SwiftData
import SwiftUI

struct PageListing: View {
    @Environment(\.modelContext) var modelContext
    @Query var pages: [Page]

    var body: some View {
        List {
            ForEach(pages) { page in
                NavigationLink(value: page) {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack (alignment: .bottom) {
                                Text(page.name.uppercased())
                                    .font(.headline)
                                Text("(counts as \(page.count))")
                                    .font(.subheadline)
                                    .padding([.leading], 4)
                                    .foregroundColor(.gray)
                            }
                            Text("Notes: " + page.notes)
                        }
                        Spacer()
                        Text("\(page.features!.count) features")
                            .font(.headline)
                            .foregroundColor(page.features!.count > 0 ? .blue : Color(.textColor))
                    }
                }
            }
            .onDelete(perform: deletePages)
        }
    }
    
    init(sort: SortDescriptor<Page>) {
        _pages = Query(sort: [sort, SortDescriptor(\Page.name)])
    }
    
    func deletePages(_ indexSet: IndexSet) {
        for index in indexSet {
            let page = pages[index]
            modelContext.delete(page)
        }
    }
}

#Preview {
    PageListing(sort: SortDescriptor(\Page.name))
}
