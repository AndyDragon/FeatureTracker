//
//  PageEditor.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-07.
//

import SwiftData
import SwiftUI
import SwiftyBeaver

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
    @State private var hub = ""
    @State private var notes = ""
    @State private var count = 1
    @State private var isChallenge = false

    private let debounce: TimeInterval = 0.2
    private let logger = SwiftyBeaver.self

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
                .help("Delete this page")

                Button(action: onClose) {
                    Image(systemName: "xmark")
                }
                .frame(alignment: .center)
                .help("Close this page")
            }.padding([.bottom], 8)
            Form {
                TextField("Name: ", text: $name)
                    .onChange(of: name, debounceTime: debounce) { newValue in
                        if page.name != newValue {
                            page.name = newValue
                        }
                    }

                TextField("Hub: ", text: $hub)
                    .onChange(of: hub, debounceTime: debounce) { newValue in
                        if page.hub != newValue {
                            page.hub = newValue
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
                        logger.verbose("Tapped to add feature", context: "User")
                        let feature = Feature()
                        page.features!.append(feature)
                        selectedFeature = feature
                        logger.verbose("Added feature", context: "System")
                    }) {
                        Image(systemName: "plus")
                    }
                    .frame(alignment: .center)
                    .help("Add a feature to this page")
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
            if oldPage.hub != hub {
                oldPage.hub = hub
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
        hub = page.hub
        notes = page.notes
        count  = page.count
        isChallenge = page.isChallenge
    }
}
