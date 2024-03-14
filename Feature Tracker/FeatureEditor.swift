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
                Button(action: onClose) {
                    Image(systemName: "xmark")
                }
                .frame(alignment: .center)
            }.padding([.bottom], 8)
            Form {
                HStack(alignment: .center) {
                    DatePicker("Date: ", selection: $date, displayedComponents: [.date])
                        .datePickerStyle(.stepperField)
                        .onChange(of: date, debounceTime: 1) { newValue in
                            feature.date = newValue
                        }
                    Spacer()
                    Toggle("RAW", isOn: $raw)
                        .onChange(of: raw, debounceTime: 1) { newValue in
                            feature.raw = newValue
                        }
                }
                TextField("Notes: ", text: $notes, axis: .vertical)
                    .onChange(of: notes, debounceTime: 1) { newValue in
                        feature.notes = newValue
                    }
            }
        }
        .onChange(of: feature, initial: true) {
            // When the feature changes, initialize the editor, but save any in-flight data
            storeInFlightData()
            loadDataIntoEditor()
            currentFeature = feature
        }
    }
    
    private func storeInFlightData() {
        if let oldFeature = currentFeature {
            oldFeature.date = date
            oldFeature.raw = raw
            oldFeature.notes = notes
        }
    }
    
    private func loadDataIntoEditor() {
        date = feature.date
        raw  = feature.raw
        notes = feature.notes
    }
}
