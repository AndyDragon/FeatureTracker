//
//  View+Extensions.swift
//  Advanced Toast
//
//  Created by Gaurav Tak on 26/12/23.
//  Modified by Andrew Forget on 2025-01-10.
//

import SwiftUI

extension View {
    func advancedToastView(toasts: Binding<[AdvancedToast]>) -> some View {
        self.modifier(AdvancedToastModifiers(toasts: toasts))
    }
}
