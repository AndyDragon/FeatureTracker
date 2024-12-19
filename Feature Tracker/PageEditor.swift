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

    // Editor state
    @State private var currentPage: Page? = nil
    @State private var name = ""
    @State private var notes = ""
    @State private var count = 1
    @State private var isChallenge = false

    private let debounce: TimeInterval = 0.2

    var body: some View {
        VStack {
            HStack {
                Text("Page / challenge:")
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
                TextField("Name: ", text: $name)
                    .onChange(of: name, debounceTime: debounce) { newValue in
                        if page.name != newValue {
                            page.name = newValue
                        }
                    }
                
                TextField("Notes: ", text: $notes, axis: .vertical)
                    .onChange(of: notes, debounceTime: debounce) { newValue in
                        if page.notes != newValue {
                            page.notes = newValue
                        }
                    }
                
                Toggle(" Was challenge", isOn: $isChallenge)
                    .onChange(of: isChallenge, debounceTime: debounce) { newValue in
                        if page.isChallenge != newValue {
                            page.isChallenge = newValue
                        }
                    }

                Picker("Counts as: ", selection: $count) {
                    ForEach(1..<6) {
                        Text("\($0)").tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.top], 1)
                .onChange(of: count, debounceTime: debounce) { newValue in
                    if page.count != newValue {
                        page.count = newValue
                    }
                }
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
        .onChange(of: page, initial: true) {
            // When the page changes, initialize the editor, but save any in-flight data
            storeInFlightData()
            loadDataIntoEditor()
            currentPage = page
        }
        .testBackground()
    }
    
    private func storeInFlightData() {
        if let oldPage = currentPage {
            if oldPage.name != name {
                oldPage.name = name
            }
            if oldPage.notes != notes {
                oldPage.notes = notes
            }
            if oldPage.count != count {
                oldPage.count = count
            }
            if oldPage.isChallenge != isChallenge {
                oldPage.isChallenge = isChallenge
            }
        }
    }
    
    private func loadDataIntoEditor() {
        name = page.name
        notes = page.notes
        count  = page.count
        isChallenge = page.isChallenge
    }
}
