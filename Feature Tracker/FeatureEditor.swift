//
//  FeatureEditor.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2024-02-13.
//

import SwiftUI

struct FeatureEditor: View {
    @Bindable var feature: Feature
    var onDelete: () -> Void
    var onClose: () -> Void = {}

    // Editor state
    @State private var currentFeature: Feature? = nil
    @State private var date = Date.now
    @State private var raw = false
    @State private var notes = ""

    private let debounce: TimeInterval = 0.2

    var body: some View {
        VStack {
            HStack {
                Text("Feature:")
                    .frame(alignment: .center)
                    .fontWeight(.bold)
                
                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .frame(alignment: .center)
                .help("Delete this feature")

                Button(action: onClose) {
                    Image(systemName: "xmark")
                }
                .frame(alignment: .center)
                .help("Close this feature")
            }.padding([.bottom], 8)
            Form {
                HStack(alignment: .center) {
                    DatePicker("Date: ", selection: $date, displayedComponents: [.date])
                        .datePickerStyle(.stepperField)
                        .onChange(of: date, debounceTime: debounce) { newValue in
                            if (feature.date != newValue) {
                                feature.date = newValue
                            }
                        }
                    Spacer()
                    Toggle("RAW", isOn: $raw)
                        .onChange(of: raw, debounceTime: debounce) { newValue in
                            if (feature.raw != newValue) {
                                feature.raw = newValue
                            }
                        }
                }
                TextField("Notes: ", text: $notes, axis: .vertical)
                    .onChange(of: notes, debounceTime: debounce) { newValue in
                        if (feature.notes != newValue) {
                            feature.notes = newValue
                        }
                    }
            }
        }
        .onChange(of: feature, initial: true) {
            // When the feature changes, initialize the editor, but save any in-flight data
            storeInFlightData()
            loadDataIntoEditor()
            currentFeature = feature
        }
        .testBackground()
    }
    
    private func storeInFlightData() {
        if let oldFeature = currentFeature {
            if oldFeature.date != date {
                oldFeature.date = date
            }
            if oldFeature.raw != raw {
                oldFeature.raw = raw
            }
            if oldFeature.notes != notes {
                oldFeature.notes = notes
            }
        }
    }
    
    private func loadDataIntoEditor() {
        date = feature.date
        raw  = feature.raw
        notes = feature.notes
    }
}
