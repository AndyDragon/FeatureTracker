//
//  AdvancedToastStyle.swift
//  Advanced Toast
//
//  Created by Gaurav Tak on 26/12/23.
//  Modified by Andrew Forget on 2025-01-10.
//

import SwiftUI

enum AdvancedToastStyle: String, CaseIterable {
    case fatal = "Critical Error"
    case error = "Error"
    case alert = "Alert"
    case warning = "Warning"
    case info = "Info"
    case success = "Success"
    case progress = "Progress"
}

extension AdvancedToastStyle {
    var themeColor: Color {
        switch self {
        case .fatal: return Color.red
        case .error: return Color.red
        case .alert: return Color.orange
        case .warning: return Color.yellow
        case .info: return Color.blue
        case .success: return Color.green
        case .progress: return Color.indigo
        }
    }

    var iconFileName: String {
        switch self {
        case .fatal: return "xmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .alert: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .progress: return ""
        }
    }

    var duration: Double {
        switch self {
        case .fatal: return .greatestFiniteMagnitude
        case .error: return .greatestFiniteMagnitude
        case .alert: return 10
        case .warning: return 10
        case .info: return 4
        case .success: return 2
        case .progress: return .greatestFiniteMagnitude
        }
    }

    var modal: Bool {
        switch self {
        case .fatal: return true
        case .error: return true
        case .alert: return true
        case .warning: return true
        case .info: return false
        case .success: return false
        case .progress: return true
        }
    }

    var blocking: Bool {
        switch self {
        case .fatal: return true
        case .error: return false
        case .alert: return false
        case .warning: return false
        case .info: return false
        case .success: return false
        case .progress: return true
        }
    }
}
