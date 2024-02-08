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
    @State private var featureDate = Date.now
    @State private var featureRaw = false
    @State private var featureNotes = ""

    var body: some View {
        VStack {
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
            Section("Features: (\(page.features!.count) feature(s))") {
                FeatureListing(page: page)
            }
            Spacer()
                .frame(height: 30)
            Section("New feature:") {
                Form {
                    HStack(alignment: .center) {
                        DatePicker("Date: ", selection: $featureDate, displayedComponents: [.date])
                            .datePickerStyle(.stepperField)
                        Spacer()
                        Toggle("RAW", isOn: $featureRaw)
                    }
                    TextField("Notes: ", text: $featureNotes, axis: .vertical)
                    Button("Add feature", action: addFeature)
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Page / Challenge details")
    }

    func addFeature() -> Void {
        let feature = Feature(date: featureDate, raw: featureRaw, notes: featureNotes)
        page.features!.append(feature)
        // clear feature editor
        featureDate = .now
        featureRaw = false
        featureNotes = ""
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Page.self, configurations: config)
        let example = Page(name: "Sample", notes: "This is notes", count: 3)
        return PageEditor(page: example).modelContainer(container)
    } catch {
        fatalError("Failed to create sample page")
    }
}
