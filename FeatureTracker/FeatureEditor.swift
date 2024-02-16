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
                    DatePicker("Date: ", selection: $feature.date, displayedComponents: [.date])
                        .datePickerStyle(.stepperField)
                    Spacer()
                    Toggle("RAW", isOn: $feature.raw)
                }
                TextField("Notes: ", text: $feature.notes, axis: .vertical)
            }
        }
    }
}
