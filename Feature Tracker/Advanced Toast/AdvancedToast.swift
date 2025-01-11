//
//  AdvancedToast.swift
//  Advanced Toast
//
//  Created by Gaurav Tak on 26/12/23.
//  Modified by Andrew Forget on 2025-01-10.
//

import SwiftUI

struct AdvancedToast: Equatable, Identifiable {
    let id = UUID()

    static func == (lhs: AdvancedToast, rhs: AdvancedToast) -> Bool {
        return lhs.id == rhs.id
    }
    
    var type: AdvancedToastStyle
    var title: String
    var message: String
    var duration: Double = .greatestFiniteMagnitude
    var modal = false
    var blocking = false
    var width: CGFloat = 400
    var buttonTitle = "Dismiss"
    var onButtonTapped: (() -> Void)?
    var onDismissed: (() -> Void)?
    var isDismissed = false

    init(
        type: AdvancedToastStyle,
        title: String,
        message: String,
        duration: Double? = nil,
        modal: Bool? = nil,
        blocking: Bool? = nil,
        width: CGFloat? = nil,
        buttonTitle: String? = nil,
        onButtonTapped: (() -> Void)? = nil,
        onDismissed: (() -> Void)? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration ?? type.duration
        self.modal = modal ?? type.modal
        self.blocking = blocking ?? type.blocking
        self.width = width ?? 400
        if let buttonTitle {
            self.buttonTitle = buttonTitle
        }
        if let onButtonTapped {
            self.onButtonTapped = onButtonTapped
        }
        if let onDismissed {
            self.onDismissed = onDismissed
        }
    }
}
