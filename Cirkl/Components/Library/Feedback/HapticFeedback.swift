//
//  HapticFeedback.swift
//  Cirkl
//
//  Created by Claude on 12/01/2026.
//

import SwiftUI
import UIKit

// MARK: - Haptic Feedback Service

/// Centralized haptic feedback service for consistent tactile responses
enum CirklHaptics {

    // MARK: - Impact Feedback

    /// Light impact - for subtle interactions like scrolling
    static func light() {
        impact(.light)
    }

    /// Medium impact - for standard button taps
    static func medium() {
        impact(.medium)
    }

    /// Heavy impact - for significant actions
    static func heavy() {
        impact(.heavy)
    }

    /// Soft impact - for gentle feedback
    static func soft() {
        impact(.soft)
    }

    /// Rigid impact - for firm feedback
    static func rigid() {
        impact(.rigid)
    }

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Selection Feedback

    /// Selection change - for picker changes, toggles
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // MARK: - Notification Feedback

    /// Success notification - for completed actions
    static func success() {
        notification(.success)
    }

    /// Warning notification - for alerts
    static func warning() {
        notification(.warning)
    }

    /// Error notification - for failures
    static func error() {
        notification(.error)
    }

    private static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    // MARK: - Custom Patterns

    /// Bubble tap - light selection for orbital bubbles
    static func bubbleTap() {
        selection()
    }

    /// Bubble long press - for context menus
    static func bubbleLongPress() {
        medium()
    }

    /// Verification success - celebratory feedback
    static func verificationSuccess() {
        success()
        // Add a second subtle tap for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            light()
        }
    }

    /// Celebration - multi-burst haptic for milestones (first connection, achievements)
    static func celebration() {
        // Initial success burst
        success()
        // Follow-up rhythmic pattern for celebration feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            light()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            medium()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            success()
        }
    }

    /// Connection created - success with emphasis
    static func connectionCreated() {
        success()
    }

    /// Mode toggle - for switching between verified/pending
    static func modeToggle() {
        selection()
    }

    /// Pull to refresh - light feedback during pull
    static func pullToRefresh() {
        light()
    }

    /// Scan complete - QR/NFC scan success
    static func scanComplete() {
        success()
    }

    /// Send message - subtle confirmation
    static func sendMessage() {
        soft()
    }

    /// Delete action - warning before destructive action
    static func deleteAction() {
        warning()
    }

    /// Error occurred - failure feedback
    static func errorOccurred() {
        error()
    }
}

// MARK: - View Modifier for Haptic on Tap

struct HapticTapModifier: ViewModifier {

    let hapticType: HapticType
    let action: () -> Void

    enum HapticType {
        case light
        case medium
        case heavy
        case selection
        case success
        case warning
        case error
    }

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                triggerHaptic()
                action()
            }
    }

    private func triggerHaptic() {
        switch hapticType {
        case .light: CirklHaptics.light()
        case .medium: CirklHaptics.medium()
        case .heavy: CirklHaptics.heavy()
        case .selection: CirklHaptics.selection()
        case .success: CirklHaptics.success()
        case .warning: CirklHaptics.warning()
        case .error: CirklHaptics.error()
        }
    }
}

extension View {
    /// Adds haptic feedback on tap
    func hapticTap(
        _ type: HapticTapModifier.HapticType = .medium,
        action: @escaping () -> Void
    ) -> some View {
        modifier(HapticTapModifier(hapticType: type, action: action))
    }
}

// MARK: - Sensory Feedback View Modifier (iOS 17+)

struct SensoryFeedbackModifier<T: Equatable>: ViewModifier {

    let feedback: SensoryFeedback
    let trigger: T

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(feedback, trigger: trigger)
    }
}

extension View {
    /// Adds sensory feedback when trigger changes (iOS 17+)
    func cirklFeedback<T: Equatable>(
        _ feedback: SensoryFeedback,
        trigger: T
    ) -> some View {
        modifier(SensoryFeedbackModifier(feedback: feedback, trigger: trigger))
    }
}

// MARK: - Design Token Extension

extension DesignTokens {

    /// Haptic feedback patterns for design system
    enum Haptics {

        /// Standard haptic patterns
        static func selection() { CirklHaptics.selection() }
        static func success() { CirklHaptics.success() }
        static func error() { CirklHaptics.error() }
        static func warning() { CirklHaptics.warning() }
        static func light() { CirklHaptics.light() }
        static func medium() { CirklHaptics.medium() }
        static func heavy() { CirklHaptics.heavy() }

        /// App-specific patterns
        static func bubbleTap() { CirklHaptics.bubbleTap() }
        static func verificationSuccess() { CirklHaptics.verificationSuccess() }
        static func connectionCreated() { CirklHaptics.connectionCreated() }
        static func modeToggle() { CirklHaptics.modeToggle() }
    }
}

// MARK: - Accessibility Extension

extension DesignTokens {

    /// Accessibility constants
    enum Accessibility {
        /// Minimum touch target size (Apple HIG)
        static let minimumTouchTarget: CGFloat = 44

        /// Minimum contrast ratio for WCAG AA compliance
        static let minimumContrastRatio: Double = 4.5

        /// Large text minimum contrast ratio
        static let largeTextMinimumContrastRatio: Double = 3.0

        /// Recommended spacing for touch targets
        static let touchTargetSpacing: CGFloat = 8
    }
}

// MARK: - Previews

#Preview("Haptic Feedback Demo") {
    VStack(spacing: 20) {
        Text("Haptic Feedback Demo")
            .font(.title)

        Button("Light Impact") { CirklHaptics.light() }
        Button("Medium Impact") { CirklHaptics.medium() }
        Button("Heavy Impact") { CirklHaptics.heavy() }

        Divider()

        Button("Selection") { CirklHaptics.selection() }

        Divider()

        Button("Success") { CirklHaptics.success() }
        Button("Warning") { CirklHaptics.warning() }
        Button("Error") { CirklHaptics.error() }

        Divider()

        Button("Bubble Tap") { CirklHaptics.bubbleTap() }
        Button("Verification Success") { CirklHaptics.verificationSuccess() }
    }
    .padding()
}
