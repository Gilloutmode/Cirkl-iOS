//
//  ThemeMode.swift
//  Cirkl
//
//  Created by Claude on 11/01/2026.
//

import SwiftUI

/// Represents the available theme modes for the app
enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case light
    case dark
    case auto

    var id: String { rawValue }

    /// Localized display name for the theme mode
    var displayName: String {
        switch self {
        case .light:
            return String(localized: "Clair")
        case .dark:
            return String(localized: "Sombre")
        case .auto:
            return String(localized: "Automatique")
        }
    }

    /// SF Symbol icon name for the theme mode
    var icon: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .auto:
            return "circle.lefthalf.filled"
        }
    }

    /// Description text explaining the theme mode behavior
    var description: String {
        switch self {
        case .light:
            return String(localized: "Toujours utiliser le mode clair")
        case .dark:
            return String(localized: "Toujours utiliser le mode sombre")
        case .auto:
            return String(localized: "Suivre les r\u{00E9}glages syst\u{00E8}me")
        }
    }

    /// Icon color for the theme mode
    var iconColor: Color {
        switch self {
        case .light:
            return .orange
        case .dark:
            return .indigo
        case .auto:
            return .blue
        }
    }
}
