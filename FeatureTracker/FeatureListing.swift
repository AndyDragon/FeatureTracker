//
//  PageListing.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import SwiftData
import SwiftUI

struct FeatureListing: View {
    @Bindable var page: Page
    
    var body: some View {
        List {
            ForEach(page.features!.sorted { $0.date < $1.date }) { feature in
                HStack {
                    VStack(alignment: .leading) {
                        HStack (alignment: .bottom) {
                            Text(feature.date.formatted(date: .long, time: .omitted))
                                .font(.headline)
                            if feature.raw {
                                Text("RAW")
                                    .font(.subheadline)
                                    .padding([.leading], 4)
                                    .foregroundColor(.gray)
                            }
                        }
                        Text("Notes: " + feature.notes)
                    }
                    Spacer()                    
                }
            }
            .onDelete(perform: deleteFeatures)
        }
    }
    
    func deleteFeatures(_ indexSet: IndexSet) {
        for index in indexSet {
            page.features!.remove(at: index)
        }
    }
}

#Preview {
    FeatureListing(page: Page())
}
