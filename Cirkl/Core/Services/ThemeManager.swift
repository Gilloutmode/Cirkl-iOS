//
//  ThemeManager.swift
//  Cirkl
//
//  Created by Claude on 11/01/2026.
//

import SwiftUI

/// Manages the app's theme preferences with persistence
@Observable
@MainActor
final class ThemeManager {

    // MARK: - Singleton

    static let shared = ThemeManager()

    // MARK: - Storage

    /// Persistent storage - marked as ignored since we use currentMode for observation
    @ObservationIgnored
    @AppStorage("app_theme_mode") private var storedThemeMode: String = ThemeMode.auto.rawValue

    // MARK: - Observable State

    /// The current theme mode - this is the observable property that triggers UI updates
    private(set) var currentMode: ThemeMode = .auto

    // MARK: - Properties

    /// The current theme mode (read/write access)
    var themeMode: ThemeMode {
        get { currentMode }
        set {
            currentMode = newValue
            storedThemeMode = newValue.rawValue
        }
    }

    /// Returns the ColorScheme to apply based on current theme mode
    /// - Returns: `.light`, `.dark`, or `nil` (follows system)
    var colorScheme: ColorScheme? {
        switch currentMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return nil // Follow system setting
        }
    }

    // MARK: - Initialization

    private init() {
        // Synchronize with persisted value on startup
        currentMode = ThemeMode(rawValue: storedThemeMode) ?? .auto
    }

    // MARK: - Methods

    /// Sets the theme mode with animation
    /// - Parameter mode: The new theme mode to apply
    func setTheme(_ mode: ThemeMode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            themeMode = mode
        }
    }

    /// Cycles through available theme modes
    func cycleTheme() {
        let modes = ThemeMode.allCases
        guard let currentIndex = modes.firstIndex(of: currentMode) else { return }
        let nextIndex = (currentIndex + 1) % modes.count
        setTheme(modes[nextIndex])
    }
}

// MARK: - Environment Key

// DATA RACE FIX: EnvironmentKey protocol requires synchronous access,
// but ThemeManager.shared is @MainActor isolated. Solution:
// 1. Use optional defaultValue (nil) to avoid accessing shared at static init time
// 2. In getter, use MainActor.assumeIsolated since SwiftUI environment access is always on main thread
private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue: ThemeManager? = nil
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get {
            // SwiftUI environment is always accessed from main thread
            // Use assumeIsolated to safely access @MainActor property
            if let stored = self[ThemeManagerKey.self] {
                return stored
            }
            // Fallback to shared instance - safe because SwiftUI runs on main thread
            return MainActor.assumeIsolated { ThemeManager.shared }
        }
        set { self[ThemeManagerKey.self] = newValue }
    }
}
