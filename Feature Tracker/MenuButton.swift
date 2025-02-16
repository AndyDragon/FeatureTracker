//
//  MenuButton.swift
//  Feature Tracker
//
//  Created by Andrew Forget on 2025-02-16.
//

import SwiftUI

struct MenuButton: View {
    var action: () -> Void
    var text: String
    var systemImage: String

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .padding(.trailing, 4)
                    .foregroundStyle(Color.accentColor, Color.secondary)
                Text(text)
            }
        }
    }
}

struct MenuButton_Previews: PreviewProvider {
    static var previews: some View {
        MenuButton(
            action: {},
            text: "Action",
            systemImage: "plus")
    }
}
