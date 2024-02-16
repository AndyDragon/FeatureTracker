//
//  PageEditor.swift
//  FeatureTracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import SwiftData
import SwiftUI

struct PageEditor: View {
    @Bindable var page: Page
    @Binding var selectedFeature: Feature?
    var onDelete: () -> Void
    var onDeleteFeature: (Feature) -> Void
    var onClose: () -> Void = {}
    var onCloseFeature: () -> Void = {}

    var body: some View {
        VStack {
            HStack {
                Text("Page:")
                    .frame(alignment: .center)
                    .fontWeight(.bold)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .frame(alignment: .center)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                }
                .frame(alignment: .center)
            }.padding([.bottom], 8)
            Form {
                TextField("Name: ", text: $page.name)
                TextField("Notes: ", text: $page.notes, axis: .vertical)
                Picker("Counts as: ", selection: $page.count) {
                    ForEach(1..<6) {
                        Text("\($0)").tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.top], 1)
            }
            Spacer()
                .frame(height: 30)
            VStack {
                HStack {
                    Text("Features: (\(page.features!.count))")
                        .frame(alignment: .center)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        let feature = Feature()
                        page.features!.append(feature)
                        selectedFeature = feature
                    }) {
                        Image(systemName: "plus")
                    }
                    .frame(alignment: .center)
                }
                FeatureListing(page: page, selectedFeature: $selectedFeature)
            }
            Spacer()
                .frame(height: 30)
            VStack {
                if let feature = selectedFeature {
                    FeatureEditor(feature: feature, onDelete: {
                        onDeleteFeature(feature)
                    }, onClose: {
                        onCloseFeature()
                    })
                }
            }
            .frame(height: 120)
            Spacer()
        }
        .padding([.leading, .trailing, .bottom])
    }
}
