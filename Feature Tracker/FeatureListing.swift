//
//  PageListing.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import SwiftData
import SwiftUI

struct FeatureListing: View {
    var page: Page
    @Binding var selectedFeature: Feature?
    
    var body: some View {
        List(selection: $selectedFeature) {
            ForEach(page.features!.sorted { $0.date < $1.date }, id: \.self) { feature in
                HStack {
                    VStack(alignment: .leading) {
                        HStack (alignment: .bottom) {
                            Text(feature.date.formatted(date: .long, time: .omitted))
                                .font(.headline)
                                .foregroundColor(.blue)
                                .brightness(0.3)
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
                .onTapGesture {
                    withAnimation {
                        selectedFeature = feature
                    }
                }
                .testBackground()
            }
        }
    }
}
